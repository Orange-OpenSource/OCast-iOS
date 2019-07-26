//
// ReferenceDevice.swift
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
// limitations under the License.
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
                // Release the semaphore if the application is starting
                semaphore?.signal()
            }
        }
    }
    
    public private(set) var upnpID: String
    
    public private(set) var host: String
    
    public private(set) var friendlyName: String
    
    public private(set) var modelName: String
    
    public var manufacturer: String
    
    public static var searchTarget: String {
        return "urn:cast-ocast-org:service:cast:1"
    }
    
    // MARK: - Private methods
    
    /// The web socket used to connect to the device.
    private var webSocket: WebSocketProtocol
    
    /// The DIAL service.
    private let dialService: DIALServiceProtocol
    
    /// Indicates if the application is running. This property is thread safe.
    private var isApplicationRunning = SynchronizedValue(false)
    
    /// The settings web socket URL.
    private let settingsWebSocketURL: String
    
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
    
    /// The semaphore to synchronize the websocket connection event.
    private var semaphore: DispatchSemaphore?
    
    /// The max interval to wait for the connection event.
    private let connectionEventTimeout: TimeInterval
    
    // MARK: - Public methods
    
    /// The device state.
    public private(set) var state: DeviceState = .disconnected {
        didSet {
            // Reset state every time state is modified
            if oldValue != state {
                isApplicationRunning.synchronizedValue = false
                // Release the semaphore if the application is starting
                semaphore?.signal()
                Logger.shared.log(logLevel: .debug, "State changed from \(oldValue.rawValue) to \(state.rawValue)")
            }
        }
    }
    
    // MARK: - Initializer
    
    public required convenience init(upnpDevice: UPNPDevice) {
        self.init(upnpDevice: upnpDevice,
                  webSocket: WebSocket(delegateQueue: DispatchQueue(label: "org.ocast.websocket")),
                  dialService: DIALService(forURL: upnpDevice.dialURL.absoluteString),
                  connectionEventTimeout: 60.0)
    }
    
    /// Creates a new device from an UPNP device and configuring its dependencies.
    ///
    /// - Parameters:
    ///   - upnpDevice: The `UPNPDevice`.
    ///   - webSocket: The web socket to use.
    ///   - dialService: The DIAL service to use.
    ///   - connectionEventTimeout: The timeout for waiting the connection event.
    public init(upnpDevice: UPNPDevice, webSocket: WebSocketProtocol, dialService: DIALServiceProtocol, connectionEventTimeout: TimeInterval) {
        upnpID = upnpDevice.deviceID
        host = upnpDevice.dialURL.host ?? ""
        friendlyName = upnpDevice.friendlyName
        modelName = upnpDevice.modelName
        manufacturer = upnpDevice.manufacturer
        self.webSocket = webSocket
        self.dialService = dialService
        self.connectionEventTimeout = connectionEventTimeout
        let defaultSettingsWebSocketURL = "wss://\(host):4433/ocast"
        #if TEST
        settingsWebSocketURL = ProcessInfo.processInfo.environment["SETTINGSWEBSOCKET"] ?? defaultSettingsWebSocketURL
        #else
        settingsWebSocketURL = defaultSettingsWebSocketURL
        #endif
        
        super.init()
        
        self.webSocket.delegate = self
        registerEvents()
    }
    
    // MARK: - Device methods
    
    public func connect(_ sslConfiguration: SSLConfiguration?, completion: @escaping NoResultHandler) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .connected {
            completion(error)
            return
        }
        
        state = .connecting
        
        if let applicationName = applicationName {
            dialService.info(ofApplication: applicationName) { [weak self] result in
                guard let `self` = self else { return }
                
                switch result {
                case .success(let info):
                    Logger.shared.log(logLevel: .debug,
                                      "DIAL info request retrieved for \(applicationName): \(info.debugDescription)")
                    self.connect(to: info.webSocketURL ?? self.settingsWebSocketURL, sslConfiguration: sslConfiguration, completion)
                case .failure(let error):
                    Logger.shared.log(logLevel: .error, "DIAL info request failed: \(error)")
                    self.state = .disconnected
                    completion(OCastError.dialError)
                }
            }
        } else {
            connect(to: settingsWebSocketURL, sslConfiguration: sslConfiguration, completion)
        }
    }
    
    public func disconnect(completion: NoResultHandler?) {
        let error = self.error(forForbiddenStates: [.connecting, .disconnecting])
        if error != nil || state == .disconnected {
            completion?(error)
            return
        }
        
        state = .disconnecting
        disconnectionHandler = completion
        webSocket.disconnect()
    }
    
    public func startApplication(completion: @escaping NoResultHandler) {
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
                
                self.startApplication(applicationName, completion: completion)
            case .failure(let error):
                Logger.shared.log(logLevel: .error, "DIAL info request failed: \(error)")
                completion(OCastError.dialError)
            }
        })
    }
    
    public func stopApplication(completion: @escaping NoResultHandler) {
        guard let applicationName = applicationName else {
            completion(OCastError.applicationNameNotSet)
            return
        }
        
        dialService.stop(application: applicationName) { result in
            switch result {
            case .success:
                Logger.shared.log(logLevel: .debug, "DIAL stop request ended successfully")
                self.isApplicationRunning.synchronizedValue = false
                completion(nil)
            case .failure(let error):
                Logger.shared.log(logLevel: .error, "DIAL stop request failed: \(error)")
                completion(OCastError.dialError)
            }
        }
    }
    
    public func registerEvent(_ name: String, completion: @escaping EventHandler) {
        registeredEvents[name] = completion
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
                    NotificationCenter.default.post(name: .playbackStatusEventNotification,
                                                    object: self, userInfo: [DeviceUserInfoKey.playbackStatusUserInfoKey: playbackStatus.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode playbackStatus event")
            }
        }
        registerEvent("metadataChanged") { [weak self] data in
            if let metadata = try? JSONDecoder().decode(OCastDeviceLayer<MediaMetadata>.self, from: data) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(name: .metadataChangedEventNotification,
                                                    object: self, userInfo: [DeviceUserInfoKey.metadataUserInfoKey: metadata.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode metadataChanged event")
            }
        }
        registerEvent("updateStatus") { [weak self] data in
            if let updateStatus = try? JSONDecoder().decode(OCastDeviceLayer<UpdateStatus>.self, from: data) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(name: .updateStatusEventNotification,
                                                    object: self, userInfo: [DeviceUserInfoKey.updateStatusUserInfoKey: updateStatus.message.data.params])
                }
            } else {
                Logger.shared.log(logLevel: .error, "Can't decode updateStatus event")
            }
        }
    }
    
    /// Connects to the device.
    ///
    /// - Parameters:
    ///   - urlString: The web socket url.
    ///   - sslConfiguration: The `SSLConfiguration` used to perform the connection.
    ///   - completion: The completion block called when the connection is finished.
    /// If the error is nil, the device is connected with success.
    private func connect(to urlString: String, sslConfiguration: SSLConfiguration?, _ completion: @escaping NoResultHandler) {
        guard let url = URL(string: urlString) else {
            completion(OCastError.badApplicationURL)
            return
        }
        connectionHandler = completion
        webSocket.connect(url: url, sslConfiguration: sslConfiguration)
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
    
    /// Starts the application identified by the given application name.
    ///
    /// - Parameters:
    ///   - applicationName: The application name.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the application is started.
    private func startApplication(_ applicationName: String, completion: @escaping NoResultHandler) {
        self.dialService.start(application: applicationName, completion: { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success:
                Logger.shared.log(logLevel: .debug, "DIAL start request ended successfully")
                self.semaphore = DispatchSemaphore(value: 0)
                // Do not wait on main thread
                self.semaphoreQueue.async {
                    let dispatchResult = self.semaphore?.wait(timeout: .now() + self.connectionEventTimeout)
                    // If the application name has changed or the device is not connected, an error callback is triggered
                    if dispatchResult == .success && self.applicationName == applicationName && self.state == .connected {
                        DispatchQueue.main.async { completion(nil) }
                    } else {
                        DispatchQueue.main.async { completion(OCastError.websocketConnectionEventNotReceived) }
                    }
                }
            case .failure(let error):
                Logger.shared.log(logLevel: .error, "DIAL start request failed: \(error)")
                completion(OCastError.dialError)
            }
        })
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
            isApplicationRunning.synchronizedValue = true
            semaphore?.signal()
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
    
    /// Sends a command to an application.
    ///
    /// - Parameters:
    ///   - layer: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent and is described in `U` parameter.
    func sendToApplication<T: Encodable, U: Codable>(command: OCastDeviceLayer<T>, completion: @escaping ResultHandler<U>) {
        if isApplicationRunning.synchronizedValue {
            send(command: command, completion: completion)
        } else {
            startApplication { [weak self] error in
                if let error = error {
                    completion(nil, error)
                } else {
                    self?.send(command: command, completion: completion)
                }
            }
        }
    }
    
    /// Sends a command with a result.
    ///
    /// - Parameters:
    ///   - layer: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent and is described in `U` parameter.
    func send<T: Encodable, U: Codable>(command: OCastDeviceLayer<T>, completion: @escaping ResultHandler<U>) {
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
        send(command: command, completion: completionBlock)
    }
    
    /// Sends a command without result.
    ///
    /// - Parameters:
    ///   - command: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent.
    func send<T: Encodable>(command: OCastDeviceLayer<T>, completion: @escaping CommandResult) {
        if let error = self.error(forForbiddenStates: [.connecting, .disconnecting, .disconnected]) {
            completion(.failure(error))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(command)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                commandHandlers[command.id] = completion
                Logger.shared.log(logLevel: .debug, jsonString)
                let result = webSocket.send(jsonString)
                if case .failure(_) = result {
                    completion(.failure(OCastError.unableToSendCommand))
                    commandHandlers[command.id] = nil
                }
            } else {
                completion(.failure(OCastError.misformedCommand))
            }
        } catch {
            Logger.shared.log(logLevel: .error, "Can't encode command: \(error)")
            completion(.failure(OCastError.misformedCommand))
        }
    }
    
    // MARK: WebSocketDelegate methods
    
    public func websocket(_ websocket: WebSocketProtocol, didConnectTo url: URL?) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .connected
            
            self?.connectionHandler?(nil)
            self?.connectionHandler = nil
        }
    }
    
    public func websocket(_ websocket: WebSocketProtocol, didDisconnectWith error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            self.state = .disconnected
            
            self.commandHandlers.forEach { _, completion in
                completion(.failure(OCastError.deviceHasBeenDisconnected))
            }
            self.commandHandlers.removeAll()
            
            if let disconnectHandler = self.disconnectionHandler {
                disconnectHandler(error != nil ? OCastError.webSocketDisconnectionFailed : nil)
                self.disconnectionHandler = nil
            } else if let connectionHandler = self.connectionHandler {
                connectionHandler(error != nil ? OCastError.webSocketConnectionFailed : nil)
                self.connectionHandler = nil
            } else {
                NotificationCenter.default.post(name: .deviceDisconnectedEventNotification,
                                                object: self,
                                                userInfo: [DeviceUserInfoKey.errorUserInfoKey: OCastError.webSocketDisconnected])
            }
        }
    }
    
    public func websocket(_ websocket: WebSocketProtocol, didReceiveMessage message: String) {
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
        } catch {
            Logger.shared.log(logLevel: .error, "A bad incoming message has been received: \(error)")
        }
    }
}

/// Extension to send custom commands.
extension ReferenceDevice: SenderDevice {
    
    public func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping NoResultHandler) {
        let command = OCastDeviceLayer(source: deviceUUID, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        let completionBlock: ResultHandler<NoResult> = { _, error in
            completion(error)
        }
        if domain == .browser {
            sendToApplication(command: command, completion: completionBlock)
        } else {
            send(command: command, completion: completionBlock)
        }
    }
    
    public func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName = .browser, completion: @escaping ResultHandler<U>) {
        let command = OCastDeviceLayer(source: deviceUUID, destination: domain.rawValue, id: generateId(), status: nil, type: .command, message: message)
        if domain == .browser {
            sendToApplication(command: command, completion: completion)
        } else {
            send(command: command, completion: completion)
        }
    }
}
