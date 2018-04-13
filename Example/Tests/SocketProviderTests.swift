//
// SocketProviderTests.swift
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
// limitations under the License.
//

import XCTest
import SocketRocket
@testable import OCast

class SocketProviderTests: XCTestCase, SocketProviderDelegate {
    
    
    func testMaxPayloadSize () {
        
        let certInfo = CertificateInfo(serverRootCACertificate: nil, serverCACertificate: nil, clientCertificate: nil, password: nil)
        let socket = SocketProvider(certificateInfo: certInfo)
        socket.delegate = self
        
        var message = String(repeating: "*", count: 4095)
        XCTAssert(socket.sendMessage(message: message))
        
        message = String(repeating: "*", count: 4096)
        XCTAssert(socket.sendMessage(message: message))
        
        message = String(repeating: "*", count: 4097)
        XCTAssert(!socket.sendMessage(message: message))
    }
 
    // MARK: - SocketProvider Protocol
    func onDisconnected (from socket: SocketProvider,code: Int, reason: String!) {}
    func onConnected (from socket: SocketProvider) {}
    func onMessageReceived (from socket: SocketProvider,  message: String) {}
}
