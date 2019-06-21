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
//  ReferenceDevice.swift
//  OCast
//
//  Created by Christophe Azemar on 09/05/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

/// The handler used to manage the command results.
internal typealias CommandResult = (Result<Data?, Error>) -> Void

/// The Reference device which conforms to the OCast specification.
@objc @objcMembers
open class ReferenceDevice: NSObject, Device, WebSocketDelegate {
    
    // MARK: - Device properties
    
    public var applicationName: String? {
        didSet {
            if oldValue != applicationName {
                isApplicationRunning.synchronizedValue = false
            }
        }
    }
    
    public private(set) var applicationURL: String
    
    public private(set) var ipAddress: String
    
    public private(set) var friendlyName: String
    
    public var sslConfiguration: SSLConfiguration = SSLConfiguration(deviceCertificates: nil, clientCertificate: nil)
    
    public var manufacturer: String
    
    public static var searchTarget: String {
        return "urn:cast-ocast-org:service:cast:1"
    }
    
    // MARK: - Private methods

    /// The DIAL service.
    private let dialService: DIALService
    
    /// Indicates if the application is running. This property is thread safe.
    private var isApplicationRunning = SynchronizedValue(false)

    /// The settings web socket URL.
    private var settingsWebSocketURL: String {
        let defaultSettingsWebSocketURL = "wss://\(ipAddress):4433/ocast"
        #if TEST
        return ProcessInfo.processInfo.environment["SETTINGSWEBSOCKET"] ?? defaultSettingsWebSocketURL
        #else
        return defaultSettingsWebSocketURL
        #endif
    }
    
    /// The web socket used to connect to the device.
    private var webSocket: WebSocketProtocol?
    
    /// The connection handler to trigger when the connected is ended.
    private var connectionHandler: NoResultHandler?
    
    /// The disconnection handler to trigger when the connected is ended.
    private var disconnectionHandler: NoResultHandler?
    
    /// The command handlers to trigger when a command response is received.
    private var commandHandlers = SynchronizedDictionary<Int, CommandResult>()
    
    /// The registered event handlers to trigger when an event is received.
    private var registeredEvents = SynchronizedDictionary<String, EventHandler>()
    
    /// The device UUID.
    private let deviceUUID = UUID().uuidString
    
    /// The sequence ID.
    private var sequenceID: Int = 0

    /// The sequence queue to protect `sequenceID` from concurrent access.
    private let sequenceQueue = DispatchQueue(label: "org.ocast.sequencequeue")
    
    /// The semaphore queue to avoid dead lock.
    private let semaphoreQueue = DispatchQueue(label: "org.ocast.semaphorequeue")
    
    // The semaphore to synchronize the websocket connection event.
    private var semaphore: DispatchSemaphore
    
    // MARK: - Public methods
    
    /// The device state.
    public private(set) var state: DeviceState = .disconnected {
        didSet {
            // Reset state every time state is modified
            if oldValue != state {
                isApplicationRunning.synchronizedValue = false
                Logger.shared.log(logLevel: .debug, "State changed from \(oldValue.rawValue) to \(state.rawValue)")
            }
        }
    }
    
    // MARK: - Initializer
    
    public required init(upnpDevice: UPNPDevice) {
        ipAddress = upnpDevice.ipAddress
        applicationURL = upnpDevice.baseURL.absoluteString
        friendlyName = upnpDevice.friendlyName
        manufacturer = upnpDevice.manufacturer
        dialService = DIALService(forURL: applicationURL)
        semaphore = DispatchSemaphore(value: 0)
        
        super.init()
        
        registerEvents()
    }
    
    // MARK: - Device methods
    
    public func connect(_ configuration: SSLConfiguration, completion: @escaping NoResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .connected {
            completion(error)
            return
        }
        
        if let applicationName = applicationName {
            dialService.info(ofApplication: applicationName) { [weak self] result in
                switch result {
                case .success(let info):
                    guard let `self` = self else { return }
                    Logger.shared.log(logLevel: .debug,
                                      "DIAL info request retrieved for \(applicationName): \(info.debugDescription)")
                    self.connect(info.app2appURL ?? self.settingsWebSocketURL, andSSLConfiguration: configuration, completion)
                case .failure(let error):
                    Logger.shared.log(logLevel: .error, "DIAL info request failed: \(error)")
                    completion(error)
                }
            }
        } else {
            connect(settingsWebSocketURL, andSSLConfiguration: configuration, completion)
        }
    }
    
    public func disconnect(_ completion: @escaping NoResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .disconnected {
            completion(error)
            return
        }
        
        state = .disconnecting
        disconnectionHandler = completion
        webSocket?.disconnect()
    }
    
    public func startApplication(_ completion: @escaping NoResultHandler) {
        guard let applicationName = applicationName else {
            completion(OCastError.applicationNameNotSet)
            return
        }
        
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(error)
            return
        }
        
        dialService.info(ofApplication: applicationName, completion: { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let applicationInfo):
                Logger.shared.log(logLevel: .debug,
                                  "DIAL info request retrieved for \(applicationName): \(applicationInfo.debugDescription)")
                self.isApplicationRunning.synchronizedValue = applicationInfo.state == .running
                guard !self.isApplicationRunning.synchronizedValue else {
                    completion(nil)
                    return
                }
                
                self.dialService.start(application: applicationName, completion: { [weak self] result in
                    guard let `self` = self else { return }
                    
                    switch result {
                    case .success:
                        Logger.shared.log(logLevel: .debug, "DIAL start request ended successfully")
                        // Do not wait on main thread
                        self.semaphoreQueue.async {
                            let dispatchResult = self.semaphore.wait(timeout: .now() + 60)
                            if dispatchResult == .success {
                                DispatchQueue.main.async { completion(nil) }
                            } else {
                                DispatchQueue.main.async { completion(OCastError.websocketConnectionEventNotReceived) }
                            }
                        }
                    case .failure(let error):
                        Logger.shared.log(logLevel: .error, "DIAL start request failed: \(error)")
                        completion(error)
                    }
                })
            case .failure(let error):
                Logger.shared.log(logLevel: .error, "DIAL info request failed: \(error)")
                completion(error)
            }
        })
    }
    
    public func stopApplication(_ completion: @escaping NoResultHandler) {
        guard let applicationName = applicationName else {
            completion(OCastError.applicationNameNotSet)
            return
        }
        
        dialService.stop(application: applicationName) { result in
            switch result {
            case .success:
                Logger.shared.log(logLevel: .debug, "DIAL stop request ended successfully")
                completion(nil)
            case .failure(let error):
                Logger.shared.log(logLevel: .error, "DIAL stop request failed: \(error)")
                completion(error)
            }
        }
    }
    
    public func registerEvent(_ name: String, withHandler handler: @escaping EventHandler) {
        registeredEvents[name] = handler
    }
    
    // MARK: Private methods
    
    /// Computes an error depending the current state and the forbidden states.
    ///
    /// - Parameter forbiddenStates: The forbidden states.
    /// - Returns: The `OCastErro` if there's an error, otherwise nil.
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
    
    /// Register media and settings event
    private func registerEvents() {
        registerEvent("playbackStatus") { [weak self] data in
            if let playbackStatus = try? JSONDecoder().decode(OCastDeviceLayer<MediaPlaybackStatus>.self, from: data) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(name: PlaybackStatusEventNotification,
                                                    object: self, userInfo: [PlaybackStatusUserInfoKey: playbackStatus.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode playbackStatus event")
            }
        }
        registerEvent("metadataChanged") { [weak self] data in
            if let metadata = try? JSONDecoder().decode(OCastDeviceLayer<MediaMetadata>.self, from: data) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(name: MetadataChangedEventNotification,
                                                    object: self, userInfo: [MetadataUserInfoKey: metadata.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode metadataChanged event")
            }
        }
        registerEvent("updateStatus") { [weak self] data in
            if let updateStatus = try? JSONDecoder().decode(OCastDeviceLayer<SettingsUpdateStatus>.self, from: data) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(name: UpdateStatusEventNotification,
                                                    object: self, userInfo: [UpdateStatusUserInfoKey: updateStatus.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode updateStatus event")
            }
        }
    }
    
    /// Connects to the device.
    ///
    /// - Parameters:
    ///   - url: The websocket endpoint.
    ///   - configuration: The `SSLConfiguration` used to perform the connection.
    ///   - completion: The completion block called when the connection is finished.
    /// If the error is nil, the device is connected with success.
    private func connect(_ url: String, andSSLConfiguration configuration: SSLConfiguration, _ completion: @escaping NoResultHandler) {
        guard let websocket = WebSocket(urlString: url,
                                        sslConfiguration: configuration,
                                        delegateQueue: DispatchQueue(label: "org.ocast.websocket")) else {
                                            completion(OCastError.badApplicationURL)
                                            return
        }
        
        self.webSocket = websocket
        connectionHandler = completion
        state = .connecting
        self.webSocket?.delegate = self
        self.webSocket?.connect()
    }
    
    /// Generates a new unique senquence id.
    ///
    /// - Returns: The new sequence id.
    private func generateId() -> Int {
        return sequenceQueue.sync {
            if sequenceID == Int.max {
                sequenceID = 0
            }
            sequenceID += 1
            return sequenceID
        }
    }
    
    /// Handles the command replies.
    ///
    /// - Parameters:
    ///   - jsonData: The JSON response.
    ///   - deviceLayer: The response device layer.
    private func handleReply(from jsonData: Data, _ deviceLayer: OCastDeviceLayer<OCastDefaultResponseDataLayer>) {
        let commandHandler = commandHandlers[deviceLayer.id]
        switch deviceLayer.status {
        case .ok?:
            if let code = deviceLayer.message.data.params.code, code != OCastDefaultResponseDataLayer.successCode {
                DispatchQueue.main.async { commandHandler?(.failure(OCastReplyError(code: code))) }
            } else {
                DispatchQueue.main.async { commandHandler?(.success(jsonData)) }
            }
        case .error(let error)?:
            Logger.shared.log(logLevel: .error, "Can't handle reply: \(String(describing: error))")
            DispatchQueue.main.async { commandHandler?(.failure(OCastError.transportError)) }
        case .none:
            Logger.shared.log(logLevel: .warning, "The status is missing in the reply")
            DispatchQueue.main.async { commandHandler?(.failure(OCastError.transportError)) }
        }
        
        commandHandlers.removeItem(forKey: deviceLayer.id)
    }
    
    /// Handles the connection event replies.
    ///
    /// - Parameter jsonData: The JSON response.
    /// - Throws: Throws an error if the JSON can't be decoded.
    private func handleConnectionEvent(_ jsonData: Data) throws {
        let connectEvent = try JSONDecoder().decode(OCastDeviceLayer<WebAppConnectedStatusEvent>.self, from: jsonData)
        if connectEvent.message.data.params.status == .connected {
            Logger.shared.log(logLevel: .debug, "The connected event has been received")
            semaphore.signal()
        } else if connectEvent.message.data.params.status == .disconnected {
            Logger.shared.log(logLevel: .debug, "The disconnected event has been received")
            isApplicationRunning.synchronizedValue = false
        }
    }
    
    /// Handles the registered events replies.
    ///
    /// - Parameters:
    ///   - jsonData: The JSON response.
    ///   - deviceLayer: The response device layer.
    private func handleRegisteredEvents(from jsonData: Data, _ deviceLayer: OCastDeviceLayer<OCastDefaultResponseDataLayer>) {
        if let eventName = deviceLayer.message.data.name,
            let handler = registeredEvents[eventName] {
            handler(jsonData)
        } else {
            Logger.shared.log(logLevel: .warning,
                              "Unregistered event received: \(String(describing: deviceLayer.message.data.name))")
        }
    }
    
    // MARK: Internal methods
    
    /// Sends a message to an application.
    ///
    /// - Parameters:
    ///   - layer: The device layer.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    func sendToApplication<T: Encodable, U: Codable>(layer: OCastDeviceLayer<T>, completion: @escaping ResultHandler<U>) {
        if isApplicationRunning.synchronizedValue {
            send(layer: layer, completion: completion)
        } else {
            startApplication { [weak self] error in
                if let error = error {
                    completion(nil, error)
                } else {
                    self?.send(layer: layer, completion: completion)
                }
            }
        }
    }
    
    /// Sends a message with a result.
    ///
    /// - Parameters:
    ///   - layer: The device layer.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    func send<T: Encodable, U: Codable>(layer: OCastDeviceLayer<T>, completion: @escaping ResultHandler<U>) {
        let completionBlock: CommandResult = { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(nil, OCastError.emptyReplyReceived)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(OCastDeviceLayer<U>.self, from: data)
                    completion(result.message.data.params, nil)
                } catch {
                    completion(nil, OCastError.badReplyFormatReceived)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
        send(layer: layer, completion: completionBlock)
    }
    
    /// Sends a message without result.
    ///
    /// - Parameters:
    ///   - layer: The device layer.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent.
    func send<T: Encodable>(layer: OCastDeviceLayer<T>, completion: @escaping CommandResult) {
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(.failure(error))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(layer)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                commandHandlers[layer.id] = completion
                let result = webSocket?.send(jsonString)
                if case .failure(_)? = result {
                    completion(.failure(OCastError.unableToSendCommand))
                    commandHandlers[layer.id] = nil
                }
            } else {
                completion(.failure(OCastError.misformedCommand))
            }
        } catch {
            Logger.shared.log(logLevel: .error, "Can't encode command: \(error)")
            completion(.failure(error))
        }
    }
    
    // MARK: WebSocketDelegate methods
    
    func websocket(_ websocket: WebSocketProtocol, didConnectTo url: URL) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .connected
            
            self?.connectionHandler?(nil)
            self?.connectionHandler = nil
        }
    }
    
    func websocket(_ websocket: WebSocketProtocol, didDisconnectWith error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            self.state = .disconnected
            
            self.commandHandlers.forEach { _, completion in
                completion(.failure(OCastError.deviceHasBeenDisconnected))
            }
            self.commandHandlers.removeAll()
            
            if let error = error {
                if let disconnectHandler = self.disconnectionHandler {
                    disconnectHandler(error)
                    self.disconnectionHandler = nil
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: DeviceDisconnectedEventNotification,
                                                        object: self,
                                                        userInfo: [ErrorUserInfoKey: error])
                    }
                }
            }
        }
    }
    
    func websocket(_ websocket: WebSocketProtocol, didReceiveMessage message: String) {
        guard let jsonData = message.data(using: .utf8) else { return }
        
        Logger.shared.log(logLevel: .debug, "Message received: \(message)")
        
        do {
            let deviceLayer = try JSONDecoder().decode(OCastDeviceLayer<OCastDefaultResponseDataLayer>.self, from: jsonData)
            switch deviceLayer.type {
            case .command: break
            case .reply:
                handleReply(from: jsonData, deviceLayer)
            case .event:
                if deviceLayer.message.service == OCastWebAppServiceName {
                    try handleConnectionEvent(jsonData)
                } else {
                    handleRegisteredEvents(from: jsonData, deviceLayer)
                }
            }
        } catch {}
    }
}

/// Extension to manage the custom streams.
extension ReferenceDevice: OCastSenderDevice {
    
    public func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping NoResultHandler) {
        let deviceLayer = OCastDeviceLayer(source: deviceUUID, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        let completionBlock: ResultHandler<NoResult> = { _, error in
            completion(error)
        }
        if domain == .browser {
            sendToApplication(layer: deviceLayer, completion: completionBlock)
        } else {
            send(layer: deviceLayer, completion: completionBlock)
        }
    }
    
    public func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping ResultHandler<U>) {
        let deviceLayer = OCastDeviceLayer(source: deviceUUID, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        if domain == .browser {
            sendToApplication(layer: deviceLayer, completion: completion)
        } else {
            send(layer: deviceLayer, completion: completion)
        }
    }
}
