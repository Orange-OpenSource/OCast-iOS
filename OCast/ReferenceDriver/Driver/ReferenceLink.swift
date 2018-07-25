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

public enum ReferenceDomainName: String {
    case browser = "browser"
    case settings = "settings"
    case all = "*"
}

final class ReferenceLink: Link, SocketProviderDelegate {

    // MARK: Constants
    enum MessageType: String {
        case command
        case event
        case reply
    }
    
    enum DriverError: Int {
        case commandWSNil = 0
        case commandWSKO
        case wrongPayload
        case remoteError
    }
    
    // MARK: - Interface
    weak var delegate: LinkDelegate?
    var profile: LinkProfile
    
    // MARK: - Internal
    let linkUUID = UUID().uuidString
    var commandSocket: SocketProvider?
    var sequenceID: Int = 0
    var successCallbacks: [Int: (CommandReply) -> Void] = [:]
    var errorCallbacks: [Int: (NSError?) -> Void] = [:]

    // MARK: Driver methods
    init(withDelegate delegate: LinkDelegate?, andProfile profile: LinkProfile) {
        self.delegate = delegate
        self.profile = profile
    }

    func connect() -> Bool {
        // if socket already exists
        commandSocket?.delegate = nil
        commandSocket?.disconnect()

        if let socket = SocketProvider(urlString: profile.app2appURL, sslConfiguration: profile.sslConfiguration) {
            commandSocket = socket
            socket.delegate = self
            return socket.connect()
        } else {
            OCastLog.error(("WS: Cannot create the socket provider."))
            return false
        }
    }

    func disconnect() {
        OCastLog.debug(("WS: Disconnecting the Command socket"))
        commandSocket?.disconnect()
    }
    
    func send(payload: Command, forDomain domain: String, onSuccess: @escaping (CommandReply) -> Void, onError: @escaping (NSError?) -> Void) {

        guard let commandSocket = commandSocket else {
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: DriverError.commandWSNil.rawValue, userInfo: [ReferenceDriver.referenceDriverErrorDomain: "Payload could not be sent because link is not connected."])
            onError(error)
            return
        }

        guard let message = buildMessage(forDomain: domain, with: payload) else {
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: DriverError.wrongPayload.rawValue, userInfo: [ReferenceDriver.referenceDriverErrorDomain: "Payload could not be formatted properly."])
            onError(error)
            return
        }

        successCallbacks[message.sequenceId] = onSuccess
        errorCallbacks[message.sequenceId] = onError

        if !commandSocket.sendMessage(message: message.message) {
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: DriverError.commandWSKO.rawValue, userInfo: [ReferenceDriver.referenceDriverErrorDomain: "Message not sent."])
            onError(error)
            resetCallbacks(for: message.sequenceId)
        }
    }

    // MARK: - SocketProviderDelegate methods
    func socketProvider(_ socketProvider: SocketProvider, didDisconnectWithError error: Error?) {
        OCastLog.debug("WS: Command is disconnected with error : \(String(describing: error))")
        commandSocket?.delegate = nil
        commandSocket = nil
        // Close pending commands
        errorCallbacks.values.forEach { (callback) in
            callback(error as NSError?)
        }
        errorCallbacks.removeAll()
        successCallbacks.removeAll()
        delegate?.link(self, didDisconnectWith: error)
    }


    func socketProvider(_ socketProvider: SocketProvider, didConnectToURL url: URL) {
        OCastLog.debug("WS: Command is connected.")
        delegate?.linkDidConnect(self)
    }

    func socketProvider(_ socketProvider: SocketProvider, didReceiveMessage message: String) {
      
            OCastLog.debug("WS: Received data: \(message)")
            guard
                let ocastData = DataMapper().decodeOCastData(for: message),
                (ocastData.destination == linkUUID || ocastData.destination == ReferenceDomainName.all.rawValue),
                let msgType = MessageType(rawValue: ocastData.type),
                let oCastMessage = ocastData.message else {
                    OCastLog.error("Ignoring message : \(message)")
                    return
            }
            
            switch msgType {
            case .command:
                OCastLog.debug("WS: Ignoring the Command frame. This message Type is not implemented.")
            case .event:
                delegate?.link(self, didReceiveEvent: Event(source: ocastData.source, message: oCastMessage))
            case .reply:
                if ocastData.status?.uppercased() == "OK" {
                    if let successCallback = successCallbacks[ocastData.identifier] {
                        let reply = CommandReply(message: oCastMessage)
                        successCallback(reply)
                    }
                } else if let errorCallback = errorCallbacks[ocastData.identifier] {
                    let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: DriverError.remoteError.rawValue, userInfo: [ReferenceDriver.referenceDriverErrorDomain: "\(ocastData.status ?? "")"])
                    errorCallback(error)
                }
                
                resetCallbacks(for: ocastData.identifier)
            }
    }

    // MARK: Private methods
    private func getSequenceId() -> Int {

        if sequenceID == type(of: sequenceID).max {
            sequenceID = 0
        }
        sequenceID += 1
        return sequenceID
    }

    private func resetCallbacks(for id: Int) {
        successCallbacks.removeValue(forKey: id)
        errorCallbacks.removeValue(forKey: id)
    }
    
    private func buildMessage(forDomain domain: String, with payload: Command) -> (message: String, sequenceId: Int)? {
        
        let sequenceId = getSequenceId()
        
        let data: [String: Any] = [
            "dst": domain,
            "src": linkUUID,
            "type": "command",
            "id": sequenceId,
            "message": payload.params,
            ]
        
        do {
            let json = try JSONSerialization.data(withJSONObject: data, options: [])
            
            if let content = String(data: json, encoding: String.Encoding.utf8) {
                OCastLog.debug("\nSending Command:\n\(content)\n")
                return (content, sequenceId)
            }
            
        } catch {
            OCastLog.error("WS: Serialization failed for Browser domain: \(error)")
            return nil
        }
        
        return nil
    }
}
