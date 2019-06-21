//
// UDPSocket.swift
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

import CocoaAsyncSocket
import Foundation

/// Protocol for responding to socket events.
protocol UDPSocketDelegate: class {
    
    /// Tells the delegate that data is received on the socket.
    ///
    /// - Parameters:
    ///   - udpSocket: The socket informing the delegate.
    ///   - data: The buffer received.
    ///   - address: The sender.
    func udpSocket(_ udpSocket: UDPSocketProtocol, didReceive data: Data, fromHost host: String?)
    
    /// Tells the delegate that the socket is closed.
    ///
    /// - Parameters:
    ///   - udpSocket: The socket informing the delegate.
    ///   - error: The error if there's an issue, `nil` if the socket has been closed normally.
    func udpSocketDidClose(_ udpSocket: UDPSocketProtocol, with error: Error?)
}

/// Protocol to abstract the socket behavior.
protocol UDPSocketProtocol {
    
    /// Tells if the socket is already opened.
    var isOpen: Bool { get }
    
    /// The delegate.
    var delegate: UDPSocketDelegate? { get set }
    
    /// Opens a socket.
    ///
    /// - Parameter port: The port to open.
    /// - Throws: If the socket can't be binded, an error is launched.
    func open(port: UInt16) throws
    
    /// Closes the current socket.
    func close()
    
    /// Sends a payload
    ///
    /// - Parameters:
    ///   - payload: The payload to send.
    ///   - host: The remote host.
    ///   - port: The port used.
    func send(payload: Data, toHost host: String, onPort port: UInt16)
}

/// Class to manage the UDP socket.
class UDPSocket: NSObject, UDPSocketProtocol, GCDAsyncUdpSocketDelegate {
    
    /// The socket.
    private let udpSocket = GCDAsyncUdpSocket()
    
    /// Parameterized initializer.
    ///
    /// - Parameter delegateQueue: The queue on which a delegate is called (Default: main).
    init(delegateQueue: DispatchQueue = DispatchQueue.main) {
        super.init()
        
        udpSocket.setDelegate(self)
        udpSocket.synchronouslySetDelegateQueue(delegateQueue)
    }
    
    // MARK: - UDPSocketProtocol properties & methods

    weak var delegate: UDPSocketDelegate?
    
    var isOpen: Bool {
        return !udpSocket.isClosed()
    }
    
    func open(port: UInt16) throws {
        try udpSocket.bind(toPort: port)
        try udpSocket.beginReceiving()
    }
    
    func close() {
        udpSocket.close()
    }
    
    func send(payload: Data, toHost host: String, onPort port: UInt16) {
        guard isOpen else { return }
        
        udpSocket.send(payload, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
    // MARK: - GCDAsyncUdpSocketDelegate methods
    
    func udpSocket(_ udpSocket: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext _: Any?) {
        delegate?.udpSocket(self, didReceive: data, fromHost: GCDAsyncSocket.host(fromAddress: address))
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        delegate?.udpSocketDidClose(self, with: error)
    }
}
