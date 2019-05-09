//
// WebSocket.swift
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
import Starscream

/// Protocol for responding to web socket events.
protocol WebSocketDelegate: class {
    
    /// Tells the delegate that the web socket is connected.
    ///
    /// - Parameters:
    ///   - websocket: The web socket connected.
    ///   - url: The host URL.
    func websocket(_ websocket: WebSocketProtocol, didConnectTo url: URL)
    
    /// Tells the delegate that the web socket has been disconnected from the host.
    ///
    /// - Parameters:
    ///   - websocket: The web socket that was connected.
    ///   - error: The error if there's an issue, `nil` if the socket has been closed normally.
    func websocket(_ websocket: WebSocketProtocol, didDisconnectWith error: Error?)
    
    /// Tells the delegate that data is received on the web socket.
    ///
    /// - Parameters:
    ///   - websocket: The connected web socket.
    ///   - message: The message received.
    func websocket(_ websocket: WebSocketProtocol, didReceiveMessage message: String)
}

/// The send message errors.
///
/// - notConnected: The web socket is not connected.
/// - maximumPayloadReached: The payload is too long.
enum WebSocketSendError: Error {
    case notConnected, maximumPayloadReached
}

/// Protocol to abstract the web socket behavior.
protocol WebSocketProtocol {
    
    /// The delegate.
    var delegate: WebSocketDelegate? { get set }
    
    /// Connects the web socket to a remote host.
    ///
    /// - Returns: `true` if the connection is performed, `false` if the the socket is already connected.
    func connect() -> Bool
    
    /// Disconnects the web socket from the remote host.
    ///
    /// - Returns: `true` if the disconnection is performed, `false` if the the socket is not connected.
    func disconnect() -> Bool
    
    /// Sends a message on the web socket.
    ///
    /// - Parameter message: The message to send.
    /// - Returns: A `Result` containing a `WebSocketSendError` if an error occurs.
    func send(_ message: String) -> Result<Void, WebSocketSendError>
}

class WebSocket: WebSocketProtocol, Starscream.WebSocketDelegate, Starscream.WebSocketPongDelegate {
    
    /// The websocket to manage the connection.
    private let socket: Starscream.WebSocket
    
    /// The timer which manages the ping pong process.
    private var pingPongTimer: Timer?
    
    /// The current retry attempt.
    private var pingPongTimerRetry: UInt8 = 0
    
    /// The max retry attempt.
    private let pingPongTimerMaxRetry: UInt8 = 2
    
    /// The timer interval.
    private let pingPongTimerTimeInterval = 5.0
    
    /// The maximum payload size.
    private let maxPayloadSize: Int = 4096
    
    /// Parameterized initializer. If the URL is not valid, the initializer will fail.
    ///
    /// - Parameters:
    ///   - urlString: The URL used to perform the connection.
    ///   - sslConfiguration: The SSL configuration for secure connections.
    init?(urlString: String, sslConfiguration: SSLConfiguration?) {
        guard let url = URL(string: urlString) else { return nil }
        
        socket = Starscream.WebSocket(url: url)
        
        setup(sslConfiguration: sslConfiguration)
        socket.delegate = self
        socket.pongDelegate = self
    }
    
    // MARK - WebSocketProtocol properties & methods
    
    weak var delegate: WebSocketDelegate?
    
    @discardableResult
    func connect() -> Bool {
        guard !socket.isConnected else { return false }
        
        stopPingPongTimer()
        socket.connect()
        
        return true
    }
    
    @discardableResult
    func disconnect() -> Bool {
        guard socket.isConnected else { return false }
        
        stopPingPongTimer()
        socket.disconnect()
        
        return true
    }
    
    @discardableResult
    func send(_ message: String) -> Result<Void, WebSocketSendError> {
        guard socket.isConnected else { return .failure(.notConnected) }
        guard message.count <= maxPayloadSize else { return .failure(.maximumPayloadReached) }

        socket.write(string: message)
        
        return .success(())
    }
    
    // MARK: Private methods
    
    /// Setups the socket with a SSL configuration.
    ///
    /// - Parameter sslConfiguration: The SSL configuration to apply.
    private func setup(sslConfiguration: SSLConfiguration?) {
        if let sslConfiguration = sslConfiguration {
            if let deviceCertificates = sslConfiguration.deviceCertificates {
                let certificates = deviceCertificates.map({ SSLCert(data: $0) })
                let sslSecurity = SSLSecurity(certs: certificates, usePublicKeys: false)
                sslSecurity.validatedDN = sslConfiguration.validatesHost
                sslSecurity.validateEntireChain = sslConfiguration.validatesCertificateChain
                socket.security = sslSecurity
            }
            socket.disableSSLCertValidation = sslConfiguration.disablesSSLCertificateValidation
            if let clientCertificate = sslConfiguration.clientCertificate {
                socket.sslClientCertificate = try? SSLClientCertificate(pkcs12Url: clientCertificate.certificate,
                                                                        password: clientCertificate.password)
            }
        }
    }
    
    /// Sends a ping on the web socket.
    ///
    /// - Returns: `true` if the send is performed, `false` if the web socket is not connected.
    @discardableResult
    private func sendPing() -> Bool {
        guard socket.isConnected else { return false }
        
        socket.write(ping: Data())
        
        return true
    }
    
    @objc func pingPongTimerExpiry(timer _: Timer) {
        if pingPongTimerRetry >= pingPongTimerMaxRetry {
            // Force to close the socket without sending the frame to the server to be notified earlier
            socket.disconnect(forceTimeout: 0)
        } else {
            pingPongTimerRetry += 1
            startPingPongTimer()
        }
    }
    
    /// Starts the ping pong timer.
    private func startPingPongTimer() {
        pingPongTimer = Timer.scheduledTimer(timeInterval: pingPongTimerTimeInterval,
                                             target: self,
                                             selector: #selector(pingPongTimerExpiry),
                                             userInfo: nil,
                                             repeats: false)
        sendPing()
    }
    
    /// Stops the ping pong timer.
    private func stopPingPongTimer() {
        pingPongTimerRetry = 0
        pingPongTimer?.invalidate()
    }
    
    // MARK: - WebSocketDelegate methods
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        delegate?.websocket(self, didReceiveMessage: text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.websocket(self, didConnectTo: self.socket.currentURL)
        startPingPongTimer()
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        stopPingPongTimer()
        var socketError = error
        if let error = error as? WSError, error.code == CloseCode.normal.rawValue {
            socketError = nil
        }
        delegate?.websocket(self, didDisconnectWith: socketError)
    }
    
    // MARK: - WebSocketPongDelegate methods
    
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        pingPongTimerRetry = 0
    }
}
