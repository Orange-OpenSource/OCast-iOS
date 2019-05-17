//
// Copyright 2019 Orange
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
//  OCastReferenceDevice.swift
//  OCast
//
//  Created by Christophe Azemar on 09/05/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

internal typealias CommandResult = (Result<Data?, Error>) -> ()

@objc @objcMembers
open class OCastDevice: NSObject, OCastDevicePublic, SocketProviderDelegate {
    
    public private(set) var state: DeviceState = .disconnected {
        didSet {
            // Reset state every time state is modified
            if oldValue != state {
                isApplicationRunning = false
            }
        }
    }
    public private(set) var ipAddress: String
    public private(set) var applicationURL: String
    private let dialService: DIALService

    public var applicationName: String? {
        didSet {
            // Reset state if application is modified
            if oldValue != applicationName {
                isApplicationRunning = false
            }
        }
    }
    
    private var isApplicationRunning = false
    
    /// Settings web socket URL
    private var settingsWebSocketURL: String {
        let defaultSettingsWebSocketURL = "wss://\(ipAddress):4433/ocast"
        #if TEST
        return ProcessInfo.processInfo.environment["SETTINGSWEBSOCKET"] ?? defaultSettingsWebSocketURL
        #else
        return defaultSettingsWebSocketURL
        #endif
    }
    
    public var sslConfiguration: SSLConfiguration = SSLConfiguration(deviceCertificates: nil, clientCertificate: nil)
    private var websocket: SocketProvider?
    private var connectHandler: CommandWithoutResultHandler?
    private var disconnectHandler: CommandWithoutResultHandler?
    private var commandHandlers: [Int: CommandResult] = [:]
    private var registeredEvents: [String: EventHandler] = [:]
    
    let uuid = UUID().uuidString
    
    let sequenceQueue = DispatchQueue(label: "SequenceQueue")
    var sequenceID: Int = 0
    
    // Connect Event
    private var semaphore: DispatchSemaphore?
    private var isConnectedEvent = false
    
    public required init(ipAddress: String, applicationURL: String) {
        self.ipAddress = ipAddress
        self.applicationURL = applicationURL
        self.dialService = DIALService(forURL: applicationURL)
        self.semaphore = DispatchSemaphore(value: 0)
        
        super.init()
        
        registerEvents()
    }
    
    // MARK: Connect/disconnectguard let `self` = self else { return }
    
    public func connect(_ configuration: SSLConfiguration, completion: @escaping CommandWithoutResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .connected {
            completion(error)
            return
        }
        
        guard let applicationName = applicationName else {
            completion(NSOCastError(.applicationNameNotSet))
            return
        }
        
        dialService.info(ofApplication: applicationName) { [weak self] result in
            switch result {
            case .success(let info):
                guard let `self` = self else { return }
                
                guard let websocket = SocketProvider(urlString: info.app2appURL ?? self.settingsWebSocketURL, sslConfiguration: configuration) else {
                    completion(NSOCastError(.badApplicationURL))
                    return
                }
                
                self.websocket = websocket
                self.connectHandler = completion
                self.state = .connecting
                self.websocket?.delegate = self
                self.websocket?.connect()
                break
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    public func disconnect(_ completion: @escaping CommandWithoutResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .disconnected {
            completion(error)
            return
        }
        
        state = .disconnecting
        disconnectHandler = completion
        websocket?.disconnect()
    }
    
    // MARK: Events methods
    
    public func registerEvent(_ name: String, withHandler handler: @escaping EventHandler) {
        registeredEvents[name] = handler
    }
    
    // MARK: DIAL methods
    public func startApplication(_ completion: @escaping CommandWithoutResultHandler) {
        guard let applicationName = applicationName else {
            completion(NSOCastError(.applicationNameNotSet))
            return
        }
        
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(error)
            return
        }
        
        dialService.info(ofApplication: applicationName, withCompletion: { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let applicationInfo):
                if applicationInfo.state.lowercased() == "running" {
                    self.isApplicationRunning = true
                    completion(nil)
                } else {
                    self.isApplicationRunning = false
                    self.dialService.start(application: applicationName, withCompletion: { result in
                        switch result {
                        case .success(_):
                            self.isConnectedEvent = false
                            let _ = self.semaphore?.wait(timeout: .now() + 60)
                            if self.isConnectedEvent {
                                self.isApplicationRunning = true
                                completion(nil)
                            } else {
                                completion(NSOCastError(.websocketConnectionEventNotReceived))
                            }
                        case .failure(let error):
                            completion(error)
                            break
                        }
                    })
                }
                break
            case .failure(let error):
                completion(error)
                break
            }
        })
    }
    
    public func stopApplication(_ completion: @escaping CommandWithoutResultHandler) {
        guard let applicationName = applicationName else {
            completion(NSOCastError(.applicationNameNotSet))
            return
        }
        
        dialService.stop(application: applicationName) { result in
            switch result {
            case .success(_):
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    // MARK: Internal methods
    
    func sendToApplication<T: Encodable>(layer: OCastDeviceLayer<T>, withCompletionHandler handler: @escaping CommandWithoutResultHandler) {
        sendToApplication(layer: layer, withCompletion: { (result:Result<Data?, Error>) in
            switch result {
            case .success(_):
                handler(nil)
                return
            case .failure(let error):
                handler(error)
                return
            }
        })
    }
    
    func sendToApplication<T: Encodable, U: Decodable>(layer: OCastDeviceLayer<T>, withCompletionHandler handler: @escaping CommandWithResultHandler<U>) {
        sendToApplication(layer: layer, withCompletion: { (result:Result<Data?, Error>) in
            switch result {
            case .success(let data):
                guard let data = data,
                    let result = try? JSONDecoder().decode(U.self, from: data) else {
                        handler(nil, NSOCastError(.badReplyFormatReceived))
                        return
                }
                handler(result, nil)
                return
            case .failure(let error):
                handler(nil, error)
                return
            }
        })
    }
    
    func sendToApplication<T: Encodable>(layer: OCastDeviceLayer<T>, withCompletion completion: @escaping CommandResult) {
        if isApplicationRunning {
            self.send(layer: layer, withCompletion: completion)
        } else {
            startApplication { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.send(layer: layer, withCompletion: completion)
                }
            }
        }
    }
    
    func send<T: Encodable>(layer: OCastDeviceLayer<T>, withCompletionHandler handler: @escaping CommandWithoutResultHandler) {
        send(layer: layer, withCompletion: { result in
            switch result {
            case .success(_):
                handler(nil)
                return
            case .failure(let error):
                handler(error)
                return
            }
        })
    }
    
    func send<T: Encodable, U: Decodable>(layer: OCastDeviceLayer<T>, withCompletionHandler handler: @escaping CommandWithResultHandler<U>) {
        send(layer: layer, withCompletion: { result in
            switch result {
            case .success(let data):
                guard let data = data,
                    let result = try? JSONDecoder().decode(U.self, from: data) else {
                        handler(nil, NSOCastError(.badReplyFormatReceived))
                        return
                }
                handler(result, nil)
                return
            case .failure(let error):
                handler(nil, error)
                return
            }
        })
    }
    
    func send<T: Encodable>(layer: OCastDeviceLayer<T>, withCompletion completion: @escaping CommandResult) {
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(.failure(error))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(layer)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                commandHandlers[layer.id] = completion
                websocket?.sendMessage(message: jsonString)
            } else {
                completion(.failure(NSOCastError(.misformedCommand)))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: Private methods
    
    private func error(forForbiddenStates forbiddenStates: [DeviceState]) -> NSOCastError? {
        guard forbiddenStates.contains(state) else { return nil }
        
        switch state {
        case .connecting:
            return NSOCastError(.wrongStateConnecting)
        case .connected:
            return NSOCastError(.wrongStateConnected)
        case .disconnecting:
            return NSOCastError(.wrongStateDisconnecting)
        case .disconnected:
            return NSOCastError(.wrongStateDisconnected)
        }
    }
    
    private func registerEvents() {
        registerEvent("playbackStatus") { data in
            if let playbackStatus = try? JSONDecoder().decode(OCastDeviceLayer<MediaPlaybackStatus>.self, from: data) {
                NotificationCenter.default.post(name: OCastPlaybackStatusEventNotification, object: ["device": self, "event": playbackStatus.message.data.params])
            }
        }
        registerEvent("metadataChanged") { data in
            if let metadata = try? JSONDecoder().decode(OCastDeviceLayer<MediaMetadataChanged>.self, from: data) {
                NotificationCenter.default.post(name: OCastMetadataChangedEventNotification, object: ["device": self, "event": metadata.message.data.params])
            }
        }
        registerEvent("updateStatus") { data in
            if let updateStatus = try? JSONDecoder().decode(OCastDeviceLayer<SettingsUpdateStatus>.self, from: data) {
                NotificationCenter.default.post(name: OCastUpdateStatusEventNotification, object: ["device": self, "event": updateStatus.message.data.params])
            }
        }
    }
    
    private func generateId() -> Int {
        // Prevent from concurrent access
        return sequenceQueue.sync {
            if self.sequenceID == Int.max {
                self.sequenceID = 0
            }
            self.sequenceID += 1
            return sequenceID
        }
    }
    
    // MARK: SocketProviderDelegate methods
    public func socketProvider(_ socketProvider: SocketProvider, didConnectToURL url: URL) {
        state = .connected
        connectHandler?(nil)
        connectHandler = nil
    }
    
    public func socketProvider(_ socketProvider: SocketProvider, didDisconnectWithError error: Error?) {
        state = .disconnected
        
        // TODO: report reason
        //let error = NSOCastError("Socket has been disconnected with error : \(error.debugDescription)")
        commandHandlers.forEach { (_, completion) in
            completion(.failure(NSOCastError(.deviceHasBeenDisconnected)))
        }
        commandHandlers.removeAll()
        
        // TODO: Embed the socket error ?
        if let error = error {
            if let disconnectHandler = disconnectHandler {
                disconnectHandler(error)
                self.disconnectHandler = nil
            } else {
                NotificationCenter.default.post(name: OCastDeviceDisconnectedEventNotification, object: ["device": self, "error": error])
            }
        }
    }
    
    public func socketProvider(_ socketProvider: SocketProvider, didReceiveMessage message: String) {
        if let jsonData = message.data(using: .utf8) {
            do {
                let deviceLayer = try JSONDecoder().decode(OCastDeviceLayer<OCastDefaultResponseDataLayer>.self, from: jsonData)
                switch deviceLayer.type {
                case "command":
                    print("OCast: Ignore command message : \(message)")
                case "reply":
                    if let status = deviceLayer.status,
                        status.lowercased() != "ok" {
                        commandHandlers[deviceLayer.id]?(.failure(NSOCastError(.transportError, failureReason: OCastTransportErrors[status] ?? "Unknown error value : \(status)")))
                        commandHandlers.removeValue(forKey: deviceLayer.id)
                        return
                    } else if let code = deviceLayer.message.data.params.code, code != 0 {
                        // command
                        // TODO: add info about error code above OCast Specification
                        commandHandlers[deviceLayer.id]?(.failure(NSOCastError(.badCommand, failureReason: "Code: \(code)")))
                        commandHandlers.removeValue(forKey: deviceLayer.id)
                        return
                    }
                    
                    if let result = commandHandlers[deviceLayer.id] {
                        result(.success(jsonData))
                        commandHandlers.removeValue(forKey: deviceLayer.id)
                    } else {
                        print("OCast: Ignore received message : \(message)")
                    }
                case "event":
                    if deviceLayer.message.service == "org.ocast.webapp" {
                        // Connect Event
                        let connectEvent = try JSONDecoder().decode(OCastDeviceLayer<OCastWebAppConnectedStatusEvent>.self, from: jsonData)
                        if connectEvent.message.data.params.status == .connected {
                            isConnectedEvent = true
                            semaphore?.signal()
                        } else if connectEvent.message.data.params.status == .disconnected {
                            isApplicationRunning = false
                        }
                    } else { // Dispatch Event
                        if let eventName = deviceLayer.message.data.name,
                            let handler = registeredEvents[eventName] {
                            handler(jsonData)
                        } else {
                            print("OCast: Ignore received event : \(message)")
                        }
                    }
                default:
                    print("OCast: Ignore received message : \(message)")
                }
            } catch {
                print("OCast: Unable to read response : \(error.localizedDescription)")
            }
        }
    }
}

extension OCastDevice: OCastSenderDevice {
    
    public func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping CommandWithoutResultHandler) {
        let message = OCastDeviceLayer(source: uuid, destination: domain.rawValue, id: generateId(), status: nil, type: "command", message: message)
        if domain == .browser {
            sendToApplication(layer: message, withCompletionHandler: completion)
        } else {
            send(layer: message, withCompletionHandler: completion)
        }
    }
    
    public func send<T: OCastMessage, U: Decodable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping CommandWithResultHandler<U>) {
        let message = OCastDeviceLayer(source: uuid, destination: domain.rawValue, id: generateId(), status: nil, type: "command", message: message)
        if domain == .browser {
            sendToApplication(layer: message, withCompletionHandler: completion)
        } else {
            send(layer: message, withCompletionHandler: completion)
        }
    }
}
