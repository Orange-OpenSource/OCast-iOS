//
// MockUDPSocket.swift
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

/// Class to mock an UDP socket.
class MockUDPSocket: UDPSocketProtocol {
    private(set) var sendCalled = false
    private let dispatchQueue = DispatchQueue(label: "org.ocast.mockudpsocket")
    var responsePayload: String
    var responseDelay: Double
    
    private(set) var isOpen: Bool = false
    var delegate: UDPSocketDelegate?
    
    init(responsePayload: String, responseDelay: Double = 1.0) {
        self.responsePayload = responsePayload
        self.responseDelay = responseDelay
    }
    
    func open(port: UInt16) throws {
        isOpen = true
    }
    
    func close() {
        isOpen = false
        dispatchQueue.async {
            self.delegate?.udpSocketDidClose(self, with: nil)
        }
    }
    
    func send(payload: Data, toHost host: String, onPort port: UInt16) {
        sendCalled = true
        dispatchQueue.asyncAfter(deadline: .now() + responseDelay) {
            self.delegate?.udpSocket(self, didReceive: self.responsePayload.data(using: .utf8)!, fromHost: "127.0.0.1")
        }
    }
}
