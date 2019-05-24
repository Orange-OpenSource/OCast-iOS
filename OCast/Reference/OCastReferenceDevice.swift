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
open class OCastDevice: NSObject, OCastDevicePublic, WebSocketDelegate {
    
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
    public private(set) var friendlyName: String
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
    private var websocket: WebSocketProtocol?
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
    
    public required init(upnpDevice: UPNPDevice) {
        self.ipAddress = upnpDevice.ipAddress
        self.applicationURL = upnpDevice.baseURL.absoluteString
        self.friendlyName = upnpDevice.friendlyName
        self.dialService = DIALService(forURL: applicationURL)
        self.semaphore = DispatchSemaphore(value: 0)
        
        super.init()
        
        registerEvents()
    }
    
    // MARK: Connect/disconnect
    
    public func connect(_ configuration: SSLConfiguration, completion: @escaping CommandWithoutResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .connected {
            completion(error)
            return
        }
        
        guard let applicationName = applicationName else {
            completion(OCastError.applicationNameNotSet)
            return
        }
        
        dialService.info(ofApplication: applicationName) { [weak self] result in
            switch result {
            case .success(let info):
                guard let `self` = self else { return }
                
                guard let websocket = WebSocket(urlString: info.app2appURL ?? self.settingsWebSocketURL, sslConfiguration: configuration) else {
                    completion(OCastError.badApplicationURL)
                    return
                }
                
                self.websocket = websocket
                self.connectHandler = completion
                self.state = .connecting
                self.websocket?.delegate = self
                self.websocket?.connect()
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
            completion(OCastError.applicationNameNotSet)
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
                self.isApplicationRunning = applicationInfo.state == .running
                guard !self.isApplicationRunning else {
                    completion(nil)
                    return
                }
                
                self.isConnectedEvent = false
                self.dialService.start(application: applicationName, withCompletion: { result in
                    switch result {
                    case .success(_):
                        let _ = self.semaphore?.wait(timeout: .now() + 60)
                        if self.isConnectedEvent {
                            completion(nil)
                        } else {
                            completion(OCastError.websocketConnectionEventNotReceived)
                        }
                    case .failure(let error):
                        completion(error)
                    }
                })
            case .failure(let error):
                completion(error)
            }
        })
    }
    
    public func stopApplication(_ completion: @escaping CommandWithoutResultHandler) {
        guard let applicationName = applicationName else {
            completion(OCastError.applicationNameNotSet)
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
    
    func sendToApplication<T: Encodable, U: Decodable>(layer: OCastDeviceLayer<T>, completion: @escaping CommandWithResultHandler<U>) {
        if isApplicationRunning {
            self.send(layer: layer, completion: completion)
        } else {
            startApplication { error in
                if let error = error {
                    completion(nil, error)
                } else {
                    self.send(layer: layer, completion: completion)
                }
            }
        }
    }
    
    func send<T: Encodable, U: Decodable>(layer: OCastDeviceLayer<T>, completion: @escaping CommandWithResultHandler<U>) {
        let completionBlock: CommandResult = { result in
            switch result {
            case .success(let data):
                guard let data = data,
                    let result = try? JSONDecoder().decode(U.self, from: data) else {
                        completion(nil, OCastError.badReplyFormatReceived)
                        return
                }
                completion(result, nil)
                return
            case .failure(let error):
                completion(nil, error)
                return
            }
        }
        send(layer: layer, completion: completionBlock)
    }
    
    func send<T: Encodable>(layer: OCastDeviceLayer<T>, completion: @escaping CommandResult) {
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(.failure(error))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(layer)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                commandHandlers[layer.id] = completion
                let result = websocket?.send(jsonString)
                if case .failure(_)? = result {
                    completion(.failure(OCastError.unableToSendCommand))
                    commandHandlers[layer.id] = nil
                }
            } else {
                completion(.failure(OCastError.misformedCommand))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: Private methods
    
    private func error(forForbiddenStates forbiddenStates: [DeviceState]) -> OCastError? {
        guard forbiddenStates.contains(state) else { return nil }
        
        switch state {
        case .connecting:
            return .wrongStateConnecting
        case .connected:
            return .wrongStateConnected
        case .disconnecting:
            return .wrongStateDisconnecting
        case .disconnected:
            return .wrongStateDisconnected
        }
    }
    
    private func registerEvents() {
        registerEvent("playbackStatus") { data in
            if let playbackStatus = try? JSONDecoder().decode(OCastDeviceLayer<MediaPlaybackStatus>.self, from: data) {
                NotificationCenter.default.post(name: OCastPlaybackStatusEventNotification,
                                                object: self, userInfo: [OCastPlaybackStatusUserInfoKey: playbackStatus.message.data.params])
            }
        }
        registerEvent("metadataChanged") { data in
            if let metadata = try? JSONDecoder().decode(OCastDeviceLayer<MediaMetadataChanged>.self, from: data) {
                NotificationCenter.default.post(name: OCastMetadataChangedEventNotification,
                                                object: self, userInfo: [OCastMetadataUserInfoKey: metadata.message.data.params])
            }
        }
        registerEvent("updateStatus") { data in
            if let updateStatus = try? JSONDecoder().decode(OCastDeviceLayer<SettingsUpdateStatus>.self, from: data) {
                NotificationCenter.default.post(name: OCastUpdateStatusEventNotification,
                                                object: self, userInfo:[OCastUpdateStatusUserInfoKey: updateStatus.message.data.params])
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
    
    // MARK: WebSocketDelegate methods
    
    func websocket(_ websocket: WebSocketProtocol, didConnectTo url: URL) {
        state = .connected
        
        connectHandler?(nil)
        connectHandler = nil
    }
    
    func websocket(_ websocket: WebSocketProtocol, didDisconnectWith error: Error?) {
        state = .disconnected
        
        commandHandlers.forEach { (_, completion) in
            completion(.failure(OCastError.deviceHasBeenDisconnected))
        }
        commandHandlers.removeAll()
        
        if let error = error {
            if let disconnectHandler = disconnectHandler {
                disconnectHandler(error)
                self.disconnectHandler = nil
            } else {
                NotificationCenter.default.post(name: OCastDeviceDisconnectedEventNotification, object: self, userInfo: [OCastErrorUserInfoKey: error])
            }
        }
    }
    
    func websocket(_ websocket: WebSocketProtocol, didReceiveMessage message: String) {
        guard let jsonData = message.data(using: .utf8) else { return }
        
        do {
            let deviceLayer = try JSONDecoder().decode(OCastDeviceLayer<OCastDefaultResponseDataLayer>.self, from: jsonData)
            switch deviceLayer.type {
            case .command: break
            case .reply:
                handleReply(from: jsonData, deviceLayer)
            case .event:
                if deviceLayer.message.service == OCastWebAppServiceName {
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
                    }
                }
            }
        } catch {}
    }

    private func handleReply(from jsonData: Data, _ deviceLayer: OCastDeviceLayer<OCastDefaultResponseDataLayer>) {
        guard let status = deviceLayer.status else { return }
        
        switch status {
        case .ok:
            if let code = deviceLayer.message.data.params.code, code != OCastDefaultResponseDataLayer.successCode {
                commandHandlers[deviceLayer.id]?(.failure(OCastReplyError(code: code)))
            } else {
                commandHandlers[deviceLayer.id]?(.success(jsonData))
            }
        case .error(_):
            commandHandlers[deviceLayer.id]?(.failure(OCastError.transportError))
        }
        
        commandHandlers.removeValue(forKey: deviceLayer.id)
    }
}

extension OCastDevice: OCastSenderDevice {
    
    public func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping CommandWithoutResultHandler) {
        let deviceLayer = OCastDeviceLayer(source: uuid, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        let completionBlock: CommandWithResultHandler<NoResult> = { _, error in
            completion(error)
        }
        if domain == .browser {
            sendToApplication(layer: deviceLayer, completion: completionBlock)
        } else {
            send(layer: deviceLayer, completion: completionBlock)
        }
    }
    
    public func send<T: OCastMessage, U: Decodable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping CommandWithResultHandler<U>) {
        let deviceLayer = OCastDeviceLayer(source: uuid, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        if domain == .browser {
            sendToApplication(layer: deviceLayer, completion: completion)
        } else {
            send(layer: deviceLayer, completion: completion)
        }
    }
}
