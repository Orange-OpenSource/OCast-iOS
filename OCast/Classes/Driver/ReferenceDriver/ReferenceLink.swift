//
// ReferenceLink.swift
//
// Copyright 2017 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
//

import Foundation

final class ReferenceLink: LinkBuildProtocol, SocketProviderProtocol {

    // MARK: - Interface

    let linkDelegate: LinkProtocol?
    let profile: LinkProfile

    init(from sender: LinkProtocol?, profile: LinkProfile) {
        linkDelegate = sender
        self.profile = profile
    }

    func connect() {

        isDisconnecting = false

        if commandSocket == nil {
            OCastLog.debug(("WS: Creating Command socket."))
            commandSocket = SocketProvider(from: self, certInfo: profile.certInfo)
        }

        if let commandSocket = commandSocket {
            OCastLog.debug(("WS: Connecting the command socket"))

            var command = profile.app2appURL

            if profile.app2appURL == "" {
                command = "ws://\(profile.ipAddress):4434/ocast"
            }

            commandSocket.connect(with: command)
        }
    }

    func disconnect() {

        guard let commandSocket = commandSocket else {
            OCastLog.error("WS: Command socket does not exist.")
            return
        }

        OCastLog.debug(("WS: Disconnecting the Command socket"))
        isDisconnecting = true

        commandSocket.disconnect()
    }

    func sendPayload(forDomain domain: DomainName, withPaylaod paylaod: CommandStructure, onSuccess: @escaping (CommandStructure) -> Void, onError: @escaping (NSError?) -> Void) {

        guard let commandSocket = commandSocket else {
            let error = NSError(domain: ErrorDomain, code: DriverError.commandWSNil.rawValue, userInfo: [ErrorDomain: "Payload could not be sent."])
            onError(error)
            return
        }

        let result = encapsulateMessage(forDomain: domain, with: paylaod)

        guard let message = result.message else {
            let error = NSError(domain: ErrorDomain, code: DriverError.wrongPayload.rawValue, userInfo: [ErrorDomain: "Payload could not be formatted properly."])
            onError(error)
            return
        }

        successCallbacks[result.sequenceId] = onSuccess
        errorCallbacks[result.sequenceId] = onError

        if !commandSocket.sendMessage(message: message) {
            let error = NSError(domain: ErrorDomain, code: DriverError.wrongPayload.rawValue, userInfo: [ErrorDomain: "Payload exceeded 4096 bytes. Message not sent."])
            onError(error)
        }
    }

    // MARK: - Constants

    let ErrorDomain = "LinkErrorDomain"

    enum DomainName {
        case browser
        case settings
        case all

        func name() -> String {
            switch self {
            case .browser:
                return "browser"
            case .settings:
                return "settings"
            case .all:
                return "*"
            }
        }
    }

    enum MessageType: String {
        case command
        case event
        case reply
    }

    enum DriverError: Int {
        case wrongDomain = 0
        case commandWSNil
        case commandWSKO
        case wrongPayload
        case remoteError
    }

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Internal

    let linkUUID = UUID().uuidString
    var commandSocket: SocketProvider?
    var port: UInt16 = 4434
    var socketTimer: Timer?

    var commandPrefix: String!

    var isDisconnecting: Bool = false
    var sequenceID: Int = 0
    var successCallbacks: [Int: (CommandStructure) -> Void] = [:]
    var errorCallbacks: [Int: (NSError?) -> Void] = [:]

    // MARK: - SocketProvider protocol

    func onDisconnected(from socket: SocketProvider, code: Int, reason: String!) {

        if commandSocket == socket {
            OCastLog.debug("WS: Command is disconnected with code (\(code)), \(reason)")
            isDisconnecting ? linkDelegate?.onLinkDisconnected(from: profile.identifier) : linkDelegate?.onLinkFailure(from: profile.identifier)
        }

        if socket != commandSocket {
            OCastLog.debug("WS: Unknown socket. Ignoring the disconnection indication.")
        }
    }

    func onConnected(from socket: SocketProvider) {

        if commandSocket == socket {
            OCastLog.debug("WS: Command is connected.")
            linkDelegate?.onLinkConnected(from: profile.identifier)
        }

        if socket != commandSocket {
            OCastLog.debug("WS: Unknown socket. Ignoring the connection indication.")
        }
    }

    func onMessageReceived(from socket: SocketProvider, message: String) {

        if commandSocket == socket {
            onCommandWSReceivedData(text: message)
        }
    }

    func manageFatalError(with errorMessage: String?) {
        OCastLog.error("WS: Frame was NOK (id = -1). Status: \(String(describing: errorMessage))")

        _ = errorCallbacks.map { callback in
            let error = NSError(domain: ErrorDomain, code: DriverError.remoteError.rawValue, userInfo: [ErrorDomain: "\(errorMessage ?? "")"])
            callback.value(error)
        }

        resetAllCallbacks()
    }

    // MARK: - Command WebSocket Delegate

    func onCommandWSReceivedData(text: String) {

        OCastLog.debug("WS: Received data: \(text)")

        guard let dataLink = ReferenceDataMapper().referenceTransformForLink(for: text) else {
            return
        }

        if dataLink.identifier == -1 {
            return manageFatalError(with: dataLink.status)
        }

        if !(dataLink.destination == linkUUID || dataLink.destination == DomainName.all.name()) {
            OCastLog.debug("WS: Ignoring message (destination was: \(dataLink.destination)")
            return
        }

        guard let msgType = MessageType(rawValue: dataLink.type) else {
            OCastLog.error("WS: Ignoring message. messageType was: \(dataLink.type)")
            return
        }

        guard let message = dataLink.message else {
            OCastLog.error("WS: Missing message. Ignoring this frame.")
            return
        }

        OCastLog.debug("WS: Command frame was OK.")

        switch msgType {
        case .command:
            OCastLog.debug("WS: Ignoring the Command frame. This message Type is not implemented.")

        case .event:
            linkDelegate?.onEvent(payload: EventStructure(domain: dataLink.source, message: DriverDataStructure(message: message)))

        case .reply:

            let status = dataLink.status ?? ""

            if status == "OK" {

                if let successCallback = successCallbacks[dataLink.identifier] {
                    let response = CommandStructure(command: "", params: DriverDataStructure(message: message))
                    successCallback(response)
                }

            } else {

                if let errorCallback = errorCallbacks[dataLink.identifier] {
                    let error = NSError(domain: ErrorDomain, code: DriverError.remoteError.rawValue, userInfo: [ErrorDomain: "\(status)"])
                    errorCallback(error)
                }
            }

            resetCallbacks(for: dataLink.identifier)
        }
    }

    // MARK: - Payload format

    func encapsulateMessage(forDomain domain: DomainName, with payload: CommandStructure) -> (message: String?, sequenceId: Int) {

        let didFail: (String?, Int) = (nil, 0)
        let sequenceId = getSequenceId()

        let data: [String: Any] = [
            "dst": domain.name(),
            "src": linkUUID,
            "type": "command",
            "id": sequenceId,
            "message": payload.params.message ?? [:],
        ]

        do {
            let json = try JSONSerialization.data(withJSONObject: data, options: [])

            if let content = String(data: json, encoding: String.Encoding.utf8) {
                OCastLog.debug("\nSending Command:\n\(content)\n")
                return (content, sequenceId)
            }

        } catch {
            OCastLog.error("WS: Serialization failed for Browser domain: \(error)")
            return didFail
        }

        return didFail
    }

    // MARK: - LinkBuild protocol implementation

    static func make(from sender: Any, linkProfile: LinkProfile) -> LinkBuildProtocol {
        return ReferenceLink(from: sender as? LinkProtocol, profile: linkProfile)
    }

    // MARK: - Miscellaneous

    func getSequenceId() -> Int {

        if sequenceID == type(of: sequenceID).max {
            sequenceID = 0
        }
        sequenceID += 1
        return sequenceID
    }

    func resetCallbacks(for id: Int) {
        successCallbacks.removeValue(forKey: id)
        errorCallbacks.removeValue(forKey: id)
    }

    func resetAllCallbacks() {
        successCallbacks.removeAll()
        errorCallbacks.removeAll()
    }
}
