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

protocol SocketProviderProtocol {
    func onDisconnected(from socket: SocketProvider, code: Int, reason: String!)
    func onConnected(from socket: SocketProvider)
    func onMessageReceived(from socket: SocketProvider, message: String)
}

final class SocketProvider: NSObject, SRWebSocketDelegate {

    // MARK: - Interface

    let delegate: SocketProviderProtocol?
    let certInfo: CertificateInfo?
    var state: State

    init(from sender: SocketProviderProtocol?, certInfo: CertificateInfo?) {
        delegate = sender
        self.certInfo = certInfo
        state = .disconnected
    }

    enum State {
        case connected
        case disconnected
    }

    func connect(with command: String) {

        if socket == nil || (socket?.readyState != .CONNECTING && socket?.readyState != .OPEN) {
            Logger.debug("Socket: Creating a socket.")
            socket = getSocket(with: command)

            if socket == nil {
                Logger.error("Socket: Could not initialize the socket.")
            }

        } else {
            Logger.debug("Socket: Ignoring connect due to socket state = \(String(describing: socket?.readyState.rawValue))")
            delegate?.onConnected(from: self)
        }
    }

    func disconnect() {

        guard let socket = socket else {
            Logger.debug("Socket: Socket does not exists. Ignoring disconnect request.")
            return
        }

        if socket.readyState != .CLOSED {
            resetPingPongTimer()
            Logger.debug("Socket: Disconnecting.")
            socket.close()
        }
    }

    func sendMessage(message: String) -> Bool {
        let payloadSize = message.count

        if payloadSize > maxPayloadSize {
            return false
        }

        socket?.send(message)
        return true
    }

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Internal

    var socket: SRWebSocket?
    var pingPongTimerRetry: Int8 = 0
    var pingPongTimer = Timer()

    // MARK: - Private constants

    let pingPongTimerTimeout: TimeInterval = 5
    let pingPongTimerMaxRetry: Int8 = 2
    let maxPayloadSize: Int = 4096

    func getSocket(with command: String) -> SRWebSocket? {

        return getUnsecureSocket(with: command)
    }

    func getSecureSocket(with _: String) -> SRWebSocket? {
        return nil
    }

    func getUnsecureSocket(with command: String) -> SRWebSocket? {
        socket = SRWebSocket(url: URL(string: command))

        guard let socket = socket else {
            return nil
        }

        socket.open()
        socket.delegate = self as SRWebSocketDelegate

        return socket
    }

    func sendPing() {

        guard let socket = socket else {
            Logger.debug("Socket: Socket does not exists. Ignoring Ping request.")
            return
        }

        if socket.readyState == .OPEN {
            socket.sendPing(nil)
        }
    }

    // MARK: - Timer management

    @objc func pingPongTimerExpiry(timer _: Timer) {

        if pingPongTimerRetry == pingPongTimerMaxRetry {
            Logger.debug(("Socket: PingPong timer max number of retries reached. Disconnecting."))

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

    func resetPingPongTimer() {
        pingPongTimerRetry = 0
        pingPongTimer.invalidate()
    }

    // MARK: - SocketRocket delegate management

    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {

        if webSocket == socket {
            delegate?.onMessageReceived(from: self, message: message as? String ?? "")
        }
    }

    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        Logger.debug("Socket: did open")

        if webSocket == socket {
            Logger.debug("Socket: send onConnected.")
            state = .connected
            delegate?.onConnected(from: self)

            pingPongTimer = Timer.scheduledTimer(timeInterval: pingPongTimerTimeout, target: self, selector: #selector(pingPongTimerExpiry), userInfo: nil, repeats: false)
            sendPing()
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean _: Bool) {
        Logger.debug("Socket: did close")

        if webSocket == socket {
            Logger.debug("Socket: send onDisconnect")
            resetPingPongTimer()
            state = .disconnected
            delegate?.onDisconnected(from: self, code: code, reason: reason)
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        Logger.debug("Socket did fail")

        if webSocket == socket {
            Logger.debug("Socket: send onDisconnect")
            resetPingPongTimer()
            state = .disconnected
            delegate?.onDisconnected(from: self, code: 0, reason: error.localizedDescription)
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didReceivePong _: Data!) {

        if webSocket == socket {
            Logger.debug("Socket: Got a Pong")
            pingPongTimerRetry = 0
        }
    }
}
