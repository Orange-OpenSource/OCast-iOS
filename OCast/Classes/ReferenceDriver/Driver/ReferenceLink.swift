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
    let ErrorDomain = "LinkErrorDomain"
    
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
    
    // MARK: - Interface
    weak var delegate: LinkDelegate?
    var profile: LinkProfile
    
    // MARK: - Internal
    let linkUUID = UUID().uuidString
    var commandSocket: SocketProvider?
    var isDisconnecting: Bool = false
    var sequenceID: Int = 0
    var successCallbacks: [Int: (CommandReply) -> Void] = [:]
    var errorCallbacks: [Int: (NSError?) -> Void] = [:]

    // MARK: Driver methods
    init(withDelegate delegate: LinkDelegate?, andProfile profile: LinkProfile) {
        self.delegate = delegate
        self.profile = profile
    }

    func connect() {

        isDisconnecting = false
        
        if let socket = SocketProvider(urlString: profile.app2appURL, sslConfiguration: profile.sslConfiguration) {
            commandSocket = socket
            commandSocket?.delegate = self
            commandSocket?.connect()
        } else {
            OCastLog.debug(("WS: Cannot create the socket provider."))
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
    
    func send(payload: Command, forDomain domain: String, onSuccess: @escaping (CommandReply) -> Void, onError: @escaping (NSError?) -> Void) {

        guard let commandSocket = commandSocket else {
            let error = NSError(domain: ErrorDomain, code: DriverError.commandWSNil.rawValue, userInfo: [ErrorDomain: "Payload could not be sent."])
            onError(error)
            return
        }

        guard let message = encapsulateMessage(forDomain: domain, with: payload),
            let messagePayload = message.message else {
            let error = NSError(domain: ErrorDomain, code: DriverError.wrongPayload.rawValue, userInfo: [ErrorDomain: "Payload could not be formatted properly."])
            onError(error)
            return
        }

        successCallbacks[message.sequenceId] = onSuccess
        errorCallbacks[message.sequenceId] = onError

        if !commandSocket.sendMessage(message: messagePayload) {
            let error = NSError(domain: ErrorDomain, code: DriverError.wrongPayload.rawValue, userInfo: [ErrorDomain: "Payload exceeded 4096 bytes. Message not sent."])
            onError(error)
        }
    }

    // MARK: - SocketProviderDelegate methods
    func socketProvider(_ socketProvider: SocketProvider, didDisconnectWithError error: Error?) {
        if commandSocket == socketProvider {
            OCastLog.debug("WS: Command is disconnected with error : \(String(describing: error))")
            isDisconnecting ? delegate?.didDisconnect(module: profile.module) : delegate?.didFail(module: profile.module)
        }
    }

    func socketProvider(_ socketProvider: SocketProvider, didConnectToURL url: URL) {
        if commandSocket == socketProvider {
            OCastLog.debug("WS: Command is connected.")
            delegate?.didConnect(module: profile.module)
        }
    }

    func socketProvider(_ socketProvider: SocketProvider, didReceiveMessage message: String) {
        if commandSocket == socketProvider {
            OCastLog.debug("WS: Received data: \(message)")
            
            guard let ocastData = DataMapper().decodeOCastData(for: message) else {
                return
            }
            
            if ocastData.identifier == -1 {
                return manageFatalError(with: ocastData.status)
            }
            
            if !(ocastData.destination == linkUUID || ocastData.destination == ReferenceDomainName.all.rawValue) {
                OCastLog.debug("WS: Ignoring message (destination was: \(ocastData.destination)")
                return
            }
            
            guard let msgType = MessageType(rawValue: ocastData.type) else {
                OCastLog.error("WS: Ignoring message. messageType was: \(ocastData.type)")
                return
            }
            
            guard let message = ocastData.message else {
                OCastLog.error("WS: Missing message. Ignoring this frame.")
                return
            }
            
            switch msgType {
            case .command:
                OCastLog.debug("WS: Ignoring the Command frame. This message Type is not implemented.")
            case .event:
                delegate?.didReceive(event: Event(source: ocastData.source, message: message))
            case .reply:
                let status = ocastData.status ?? ""
            
                if status.uppercased() == "OK" {
                    if let successCallback = successCallbacks[ocastData.identifier] {
                        let reply = CommandReply(message: message)
                        successCallback(reply)
                    }
                } else {
                    if let errorCallback = errorCallbacks[ocastData.identifier] {
                        let error = NSError(domain: ErrorDomain, code: DriverError.remoteError.rawValue, userInfo: [ErrorDomain: "\(status)"])
                        errorCallback(error)
                    }
                }
                
                resetCallbacks(for: ocastData.identifier)
            }
        }
    }

    // MARK: Private methods
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
    
    func manageFatalError(with errorMessage: String?) {
        OCastLog.error("WS: Frame was NOK (id = -1). Status: \(String(describing: errorMessage))")
        
        let error = NSError(domain: ErrorDomain, code: DriverError.remoteError.rawValue, userInfo: [ErrorDomain: "\(errorMessage ?? "")"])
        errorCallbacks.forEach { (_, callback) in
            callback(error)
        }
        
        resetAllCallbacks()
    }
    
    func encapsulateMessage(forDomain domain: String, with payload: Command) -> (message: String?, sequenceId: Int)? {
        
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
