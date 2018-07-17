//
// OCastMockServer.swift
//
// Copyright 2018 Orange
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

import CocoaAsyncSocket
import Darwin
import Foundation
import Swifter

/// Class to mock an OCast stick
public class OCastMockServer: NSObject, GCDAsyncUdpSocketDelegate {
    
    /// Search response
    ///
    /// - ok: OK containing an UDID
    /// - error: Error
    /// - ignore: Ignore
    enum SearchResponse {
        case ok(uuid: String)
        case error
        case ignore
    }
    
    /// Location response
    ///
    /// - ok: OK containing a friendly name, manufacturer, model name and an UDID
    /// - error: Error
    enum LocationResponse {
        case ok(friendlyName: String, manufacturer: String, modelName: String, uuid: String)
        case error
    }
    
    /// Application state
    ///
    /// - running: The application is running
    /// - stopped: The application is stopped
    /// - invalid: The applicaiton is invalid
    enum AppState: String {
        case running
        case stopped
        case invalid
    }
    
    /// Application state response
    ///
    /// - ok: OK containing the application name and state
    /// - error: Error
    /// - notFound: Application not found
    enum AppStateResponse {
        case ok(name: String, state: AppState)
        case error
        case notFound
    }
    
    /// Start application response
    ///
    /// - ok: OK
    /// - error: Error
    /// - notFound: Application not found
    enum AppStartResponse {
        case ok
        case error
        case notFound
    }
    
    /// WebSocket response
    ///
    /// - ok: OK
    /// - close: Close
    enum WebSocketResponse {
        case ok
        case close
    }

    /// Class to mock requests
    class Requests {
        
        /// M-Search request
        var search: (String) -> SearchResponse
        
        /// DIAL Location request
        var location: () -> LocationResponse
        
        /// DIAL Application state request
        var appState: (String) -> AppStateResponse
        
        /// DIAL Application start request
        var appStart: (String) -> AppStartResponse
        
        /// DIAL Application stop request
        var appStop: (String) -> AppStartResponse
        
        /// Websocket connection
        var wsConnect: (_ responseWriter: @escaping (String) -> Void) -> WebSocketResponse
        
        /// Websocket message
        var wsMessage: (_ message: String, _ responseWriter: @escaping (String) -> Void) -> WebSocketResponse
        
        init(search: @escaping (String) -> SearchResponse,
             location: @escaping () -> LocationResponse,
             appState: @escaping (String) -> AppStateResponse,
             appStart: @escaping (String) -> AppStartResponse,
             appStop: @escaping (String) -> AppStartResponse,
             wsConnect: @escaping (_ responseWriter: @escaping (String) -> Void) -> WebSocketResponse,
             wsMessage: @escaping (_ message: String, _ responseWriter: @escaping (String) -> Void) -> WebSocketResponse) {
            
            self.search = search
            self.location = location
            self.appState = appState
            self.appStart = appStart
            self.appStop = appStop
            self.wsConnect = wsConnect
            self.wsMessage = wsMessage
        }
    }
    
    // MARK: Public members
    
    /// The DIAL location response
    static let xmlLocationResponse = """
    <?xml version="1.0" encoding="UTF-8"?>
    <root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:r="urn:restful-tv-org:schemas:upnp-dd">
        <specVersion>
            <major>1</major>
            <minor>0</minor>
        </specVersion>
        <device>
            <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>
            <friendlyName>%@</friendlyName>
            <manufacturer>%@</manufacturer>
            <modelName>%@</modelName>
            <UDN>%@</UDN>
        </device>
    </root>
    """
    
    /// The DIAL application response
    static let xmlAppResponse = """
    <?xml version="1.0" encoding="UTF-8"?>
    <service xmlns="urn:dial-multiscreen-org:schemas:dial" xmlns:ocast="urn:cast-ocast-org:service:cast:1" dialVer="2.1">
        <name>%@</name>
        <options allowStop="true"/>
        <state>%@</state>
        <additionalData>
            <ocast:X_OCAST_App2AppURL>%@</ocast:X_OCAST_App2AppURL>
            <ocast:X_OCAST_Version>1.0</ocast:X_OCAST_Version>
        </additionalData>
        <link rel="run" href="run"/>
    </service>
    """
    
    /// The OCast connected event response
    public static let webAppConnectedEventMessage = """
    {
        "src": "browser",
        "dst": "*",
        "id": 0,
        "type": "event",
        "message": {
            "service": "org.ocast.webapp",
            "data": {
                "name": "connectedStatus",
                "params": { "status": "connected" }
            }
        }
    }
    """
    
    // MARK: Private members

    /// The request to handle for each device
    private var requests: [String: Requests]
    
    /// The IP address
    private let ipAddress: String
    
    /// The HTTP port to use
    private let httpPort: UInt16
    
    /// The UDP socket for the M-SEARCH
    private var ssdpSocket: GCDAsyncUdpSocket?
    
    /// The HTTP server
    private let httpServer = HttpServer()
    
    // MARK: Initializer
    
    /// Initializes a new OCast mock server
    ///
    /// - Parameters:
    ///   - ipAddress: The IP address (127.0.0.1 by default)
    ///   - httpPort: The HTTP port to use to serve HTTP content
    ///   - requests: The requests to handle for each device
    init(ipAddress: String = "127.0.0.1", httpPort: UInt16, requests: [String: Requests]) {
        self.ipAddress = ipAddress
        self.httpPort = httpPort
        self.requests = requests
    }
    
    // MARK: Public methods
    
    /// Starts handling incomming DIAL requests and OCast WebSockets events
    func start() throws {
        // Listen to M-SEARCH UDP request
        ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try ssdpSocket!.bind(toPort: 1900)
            try ssdpSocket!.joinMulticastGroup("239.255.255.250")
            try ssdpSocket!.beginReceiving()
        } catch {
            ssdpSocket!.close()
            ssdpSocket = nil
        }
        
        prepareHTTPHandlers()
        
        try httpServer.start(httpPort, forceIPv4: false, priority: .background)        
    }
    
    /// Stops serving DIAL and OCast requests
    func stop() {
        ssdpSocket?.close()
        ssdpSocket = nil
        
        httpServer.stop()
    }
    
    /// Returns the application URL for a key
    ///
    /// - Parameter key: The key to use
    /// - Returns: The application URL
    func appsURL(forKey key: String) -> String {
        return "http://\(ipAddress):\(self.httpPort)/\(key)/apps"
    }
    
    /// Finds the first available port to listen a TCP connection
    ///
    /// - Parameter firstPort: The first port to try
    /// - Returns: The first available port
    /// - Throws: When no
    class func findFreePort(startingFrom firstPort: UInt16, maxAttempts: UInt16 = 100) throws -> UInt16 {
        var port = firstPort
        repeat {
            if checkListenOnTcpPort(port) {
                return port
            }
            port += 1
        } while port < firstPort + maxAttempts
        
        throw NSError(domain: "OCastMockServer", code: -1, userInfo: nil)
    }
    
    // MARK: Private methods
    
    /// Returns the location URL for a key
    ///
    /// - Parameter key: The key to use
    /// - Returns: The location URL
    private func locationURL(forKey key: String) -> String {
        return "http://\(ipAddress):\(httpPort)/\(key)/dd.xml"
    }
    
    /// Returns the websocket URL for a key
    ///
    /// - Parameter key: The key to use
    /// - Returns: The websocket URL
    private func wsURL(forKey key: String) -> String {
        return "ws://\(ipAddress):\(httpPort)/\(key)/ws"
    }

    /// Checks if the port is free to be used to listen for a TCP connection
    ///
    /// - Parameter port: The port to check
    /// - Returns: `true` when the port is free, `false` otherwise
    private class func checkListenOnTcpPort(_ port: in_port_t) -> Bool {
        let socket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard socket != -1 else {
            return false
        }
        defer {
            Darwin.shutdown(socket, SHUT_RDWR)
            close(socket)
        }
        
        var addr = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
                               sin_family: UInt8(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr: in_addr_t(0)),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        let bindResult = withUnsafePointer(to: &addr) {
            bind(socket, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        
        guard bindResult != -1 else {
            return false
        }
        return listen(socket, SOMAXCONN ) != -1
    }
    
    //swiftlint:disable cyclomatic_complexity function_body_length
    private func prepareHTTPHandlers() {
        // Listen to DIAL location and apps requests and handle websockets
        for (key, request) in requests {
            httpServer["\(key)/dd.xml"] = { _ in
                switch request.location() {
                case let .ok(friendlyName, manufacturer, modelName, uuid):
                    let headers = ["Content-Type": "application/xml",
                                   "Application-URL": self.appsURL(forKey: key)]
                    return .raw(200, "OK", headers, { writer in
                        let response = String(format: OCastMockServer.xmlLocationResponse, friendlyName, manufacturer, modelName, uuid)
                        try writer.write(response.data(using: .utf8)!)
                    })
                case .error:
                    return .internalServerError
                }
            }
            httpServer.GET["\(key)/apps/:name"] = { r in
                switch request.appState(r.params[":name"]!) {
                case let .ok(name, state):
                    return .raw(200, "OK", ["Content-Type": "application/xml"], { writer in
                        let response = String(format: OCastMockServer.xmlAppResponse, name, state.rawValue, self.wsURL(forKey: key))
                        try writer.write(response.data(using: .utf8)!)
                    })
                case .error:
                    return .internalServerError
                case .notFound:
                    return .notFound
                }
            }
            httpServer.POST["\(key)/apps/:name"] = { r in
                switch request.appStart(r.params[":name"]!) {
                case .ok:
                    return .raw(201, "Created", ["Location": self.appsURL(forKey: key) + "/run"], { _ in })
                case .error:
                    return .internalServerError
                case .notFound:
                    return .notFound
                }
            }
            httpServer.DELETE["\(key)/apps/:name/run"] = { r in
                switch request.appStop(r.params[":name"]!) {
                case .ok:
                    return .ok(.text("Deleted"))
                case .error:
                    return .internalServerError
                case .notFound:
                    return .notFound
                }
            }
            
            httpServer["/\(key)/ws"] = websocket(text: { session, payload in
                switch request.wsMessage(payload, session.writeText) {
                case .ok:
                    break
                case .close:
                    session.writeCloseFrame()
                }
            }, connected: { session in
                switch request.wsConnect(session.writeText) {
                case .ok:
                    break
                case .close:
                    session.writeCloseFrame()
                }
            })
        }
    }
    
    // MARK: GCDAsyncUdpSocketDelegate methods

    /// Handles the UDP responses to M-SEARCH requests
    public func udpSocket(_ udpSocket: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext _: Any?) {
        let request = String(bytes: data, encoding: .utf8)!
        guard request.hasPrefix("M-SEARCH * HTTP/1.1\r\n") else { return }
        let headersList = request.split(separator: "\r\n").dropFirst()
        let headers = headersList.reduce(into: [String: String]()) {
            let header = $1.split(separator: ":", maxSplits: 1)
            if header.count == 2, let key = header.first, let value = header.last {
                $0[key.uppercased()] = value.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
        guard headers["MAN"] == "\"ssdp:discover\"",
            Float(headers["MX"] ?? "-1") ?? -1 > 0,
            let searchTarget = headers["ST"] else {
                return
        }
        for (key, request) in requests {
            switch request.search(searchTarget) {
            case let .ok(uuid):
                let response = "HTTP/1.1 200 OK\r\nLOCATION: \(locationURL(forKey: key))\r\nST: \(searchTarget)\r\nUSN: \(uuid)\r\n\r\n"
                udpSocket.send(response.data(using: String.Encoding.utf8)!, toAddress: address, withTimeout: 1, tag: 0)
            case .error:
                let response = "HTTP/1.1 500 Error\r\n"
                udpSocket.send(response.data(using: String.Encoding.utf8)!, toAddress: address, withTimeout: 1, tag: 0)
            case .ignore:
                break // do not send anything back
            }
        }
    }
}
