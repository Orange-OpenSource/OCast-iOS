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
import SocketRocket

protocol SocketProviderDelegate {
    func onDisconnected(from socket: SocketProvider, code: Int, reason: String!)
    func onConnected(from socket: SocketProvider)
    func onMessageReceived(from socket: SocketProvider, message: String)
}

final class SocketProvider: NSObject, SRWebSocketDelegate {

    enum State {
        case connected
        case disconnected
    }
    
    private let certificateInfo: CertificateInfo?
    
    private var socket: SRWebSocket?
    
    private var pingPongTimerRetry: Int8 = 0
    
    private var pingPongTimer = Timer()
    
    private let pingPongTimerTimeout: TimeInterval = 5
    
    private let pingPongTimerMaxRetry: Int8 = 2
    
    private let maxPayloadSize: Int = 4096

    var delegate: SocketProviderDelegate?
    
    private(set) var state: State
    
    // MARK: Initializer
    
    init(certificateInfo: CertificateInfo?) {
        self.certificateInfo = certificateInfo
        state = .disconnected
    }
    
    // MARK: Internal methods

    func connect(with command: String) {
        if socket == nil || (socket?.readyState != .CONNECTING && socket?.readyState != .OPEN) {
            OCastLog.debug("Socket: Connecting...")
            socket = socket(with: command)
            socket?.open()
            socket?.delegate = self
        } else {
            OCastLog.debug("Socket: Ignoring connect due to socket state = \(String(describing: socket?.readyState.rawValue))")
            delegate?.onConnected(from: self)
        }
    }

    func disconnect() {
        if socket?.readyState != .CLOSED {
            resetPingPongTimer()
            OCastLog.debug("Socket: Disconnecting...")
            socket?.close()
        }
    }

    func sendMessage(message: String) -> Bool {
        guard message.count <= maxPayloadSize else { return false }
        
        socket?.send(message)
        
        return true
    }
    
    // MARK: Private methods

    private func socket(with command: String) -> SRWebSocket? {
       return SRWebSocket(url: URL(string: command), protocols: nil, allowsUntrustedSSLCertificates: true)
    }

    private func sendPing() {
        if socket?.readyState == .OPEN {
            socket?.sendPing(nil)
        }
    }

    // MARK: - Timer management

    @objc func pingPongTimerExpiry(timer _: Timer) {
        if pingPongTimerRetry == pingPongTimerMaxRetry {
            OCastLog.debug(("Socket: PingPong timer max number of retries reached. Disconnecting."))

            resetPingPongTimer()
            state = .disconnected
            delegate?.onDisconnected(from: self, code: 0, reason: "Remote seems down.")

            socket = nil

        } else {
            pingPongTimerRetry += 1
            pingPongTimer = Timer.scheduledTimer(timeInterval: pingPongTimerTimeout, target: self, selector: #selector(pingPongTimerExpiry), userInfo: nil, repeats: false)
            sendPing()
        }
    }

    private func resetPingPongTimer() {
        pingPongTimerRetry = 0
        pingPongTimer.invalidate()
    }

    // MARK: - SRWebSocketDelegate methods

    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if webSocket == socket {
            delegate?.onMessageReceived(from: self, message: message as? String ?? "")
        }
    }

    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        OCastLog.debug("Socket: did open")

        if webSocket == socket {
            OCastLog.debug("Socket: send onConnected.")
            state = .connected
            delegate?.onConnected(from: self)

            pingPongTimer = Timer.scheduledTimer(timeInterval: pingPongTimerTimeout, target: self, selector: #selector(pingPongTimerExpiry), userInfo: nil, repeats: false)
            sendPing()
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean _: Bool) {
        OCastLog.debug("Socket: did close")

        if webSocket == socket {
            OCastLog.debug("Socket: send onDisconnect")
            resetPingPongTimer()
            state = .disconnected
            delegate?.onDisconnected(from: self, code: code, reason: reason)
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        OCastLog.debug("Socket did fail")

        if webSocket == socket {
            OCastLog.debug("Socket: send onDisconnect")
            resetPingPongTimer()
            state = .disconnected
            delegate?.onDisconnected(from: self, code: 0, reason: error.localizedDescription)
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didReceivePong _: Data!) {
        if webSocket == socket {
            OCastLog.debug("Socket: Got a Pong")
            pingPongTimerRetry = 0
        }
    }
}
