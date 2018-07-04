//
// SocketProvider.swift
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

/// The delegate of a SocketProvider object must adopt the SocketProviderDelegate protocol.
public protocol SocketProviderDelegate: class {
    
    /// Tells the delegate that the socket provider is connected to the device.
    ///
    /// - Parameters:
    ///   - socketProvider: The socket provider connected.
    ///   - url: The connection URL.
    func socketProvider(_ socketProvider: SocketProvider, didConnectToURL url: URL)
    
    /// Tells the delegate that the socket provider has been disconnected from the device.
    ///
    /// - Parameters:
    ///   - socketProvider: The socket provider that was connected.
    ///   - error: The error.
    func socketProvider(_ socketProvider: SocketProvider, didDisconnectWithError error: Error?)
    
    /// Tells the delegate that the socket provider has received a message.
    ///
    /// - Parameters:
    ///   - socketProvider: The connected socket provider.
    ///   - message: The message received.
    func socketProvider(_ socketProvider: SocketProvider, didReceiveMessage message: String)
}

/// Class to manage the web socket connection
public final class SocketProvider: NSObject, WebSocketDelegate, WebSocketPongDelegate {
    
    private var socket: WebSocket
    
    private var pingPongTimerRetry: Int8 = 0
    
    private var pingPongTimer = Timer()
    
    private let pingPongTimerTimeInterval = 5.0
    
    private let pingPongTimerMaxRetry: Int8 = 2
    
    private let maxPayloadSize: Int = 4096

    public weak var delegate: SocketProviderDelegate?
    
    // MARK: Initializer
    
    /// Parameterized initializer. If the URL is not valid, the initializer will fail.
    ///
    /// - Parameters:
    ///   - urlString: The URL used to perform the connection.
    ///   - sslConfiguration: The SSL configuration for secure connections.
    public init?(urlString: String, sslConfiguration: SSLConfiguration?) {
        guard let url = URL(string: urlString) else { return nil }
        
        socket = WebSocket(url: url)
        
        super.init()
    
        setup(sslConfiguration: sslConfiguration)
        socket.delegate = self
        socket.pongDelegate = self
    }
    
    // MARK: Internal methods
    
    /// Connects the socket to the remote host.
    ///
    /// - Returns: `true` if the connection is performed, `false` if the the socket is already connected.
    @discardableResult
    public func connect() -> Bool {
        guard !socket.isConnected else { return false }
        
        stopPingPongTimer()
        OCastLog.debug("Socket: Connecting...")
        socket.connect()
        
        return true
    }

    /// Disconnects the socket from the remote host.
    ///
    /// - Returns: `true` if the disconnection is performed, `false` if the the socket is not connected.
    @discardableResult
    public func disconnect() -> Bool {
        guard socket.isConnected else { return false }

        stopPingPongTimer()
        OCastLog.debug("Socket: Disconnecting...")
        socket.disconnect()
        
        return true
    }

    /// Sends a message on the socket.
    ///
    /// - Parameter message: The message to send.
    /// - Returns: `true` if the send is performed, `false` if the the socket is not connected
    /// or the payload is too long.
    @discardableResult
    public func sendMessage(message: String) -> Bool {
        guard socket.isConnected, message.count <= maxPayloadSize else { return false }
        
        socket.write(string: message)
        
        return true
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
                socket.sslClientCertificate = try? SSLClientCertificate(pkcs12Data: clientCertificate.certificate,
                                                                        password: clientCertificate.password)
            }
        }
    }
    
    /// Sends a ping on the socket.
    ///
    /// - Returns: `true` if the send is performed, `false` if the socket is not connected.
    @discardableResult
    private func sendPing() -> Bool {
        guard socket.isConnected else { return false }
        
        socket.write(ping: Data())
        
        return true
    }

    // MARK: - Timer management

    @objc func pingPongTimerExpiry(timer _: Timer) {
        if pingPongTimerRetry == pingPongTimerMaxRetry {
            OCastLog.debug(("Socket: PingPong timer max number of retries reached. Disconnecting."))
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
        pingPongTimer.invalidate()
    }

    // MARK: - WebSocketDelegate methods

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        delegate?.socketProvider(self, didReceiveMessage: text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    }

    public func websocketDidConnect(socket: WebSocketClient) {
        OCastLog.debug("Socket: Connected")
        delegate?.socketProvider(self, didConnectToURL: self.socket.currentURL)
        startPingPongTimer()
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        OCastLog.debug("Socket: Disconnected")
        stopPingPongTimer()
        delegate?.socketProvider(self, didDisconnectWithError: error)
    }
    
    // MARK: - WebSocketPongDelegate methods
    public func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        pingPongTimerRetry = 0
    }
}
