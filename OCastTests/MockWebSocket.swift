//
// MockWebSocket.swift
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
@testable import OCast

/// The `MockWebSocket` errors
///
/// - invalidSSLError: Invalid SSL.
/// - timeoutError: Timeout.
enum MockWebSocketError: Error {
    case invalidSSLError, timeoutError
}

/// The class to mock the web socket.
class MockWebSocket: WebSocketProtocol {
    
    private let urlString: String
    private let delegateQueue: DispatchQueue
    private var socketConnected = false

    var responsePayload: String = ""
    var responseDelay: Double = 1.0
    var connectionError: Error?
    var disconnectionError: Error?
    var sendError: WebSocketSendError?
    
    weak var delegate: WebSocketDelegate?
    
    required init?(urlString: String,
                   sslConfiguration: SSLConfiguration?,
                   delegateQueue: DispatchQueue = DispatchQueue(label: "org.ocast.mocksocket")) {
        self.urlString = urlString
        self.delegateQueue = delegateQueue
    }
    
    func connect(url: URL, sslConfiguration: SSLConfiguration?) -> Bool {
        guard !socketConnected else { return false }
        
        delegateQueue.asyncAfter(deadline: .now() + responseDelay) {
            if let connectionError = self.connectionError {
                self.delegate?.websocket(self, didDisconnectWith: connectionError)
            } else {
                self.socketConnected = true
                self.delegate?.websocket(self, didConnectTo: URL(string: self.urlString)!)
            }
        }
        return true
    }
    
    func disconnect() -> Bool {
        guard socketConnected else { return false }
        
        delegateQueue.asyncAfter(deadline: .now() + responseDelay) {
            self.socketConnected = false
            self.delegate?.websocket(self, didDisconnectWith: self.disconnectionError)
        }
        
        return true
    }
    
    func send(_ message: String) -> Result<Void, WebSocketSendError> {
        guard socketConnected else { return .failure(.notConnected) }
        
        if let sendError = sendError {
            return .failure(sendError)
        } else {
            delegateQueue.asyncAfter(deadline: .now() + responseDelay) {
                self.delegate?.websocket(self, didReceiveMessage: self.responsePayload)
            }
            return .success(())
        }
    }
    
    func triggerIncomingMessage(_ message: String, after delay: TimeInterval) {
        delegateQueue.asyncAfter(deadline: .now() + delay) {
            self.delegate?.websocket(self, didReceiveMessage: message)
        }
    }
}
