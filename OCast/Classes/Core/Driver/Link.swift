//
// Link.swift
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

import Foundation

// Used for Event messages
@objc public class Event: NSObject {
    public let source: String
    public var message: [String: Any]
    public init(source: String, message: [String: Any]) {
        self.source = source
        self.message = message
    }
    
    public override var description: String {
        get {
            return "Event with source: \(source) / message: \(message)"
        }
    }
}

@objc public class Command: NSObject {
    public let command: String
    public var params: [String: Any]
    public init(command: String = "", params: [String: Any]) {
        self.command = command
        self.params = params
    }
    
    public override var description: String {
        get {
            return "Command: \(command) / Reply: \(params)"
        }
    }
}

@objc public class CommandReply: NSObject {
    public var message: [String: Any]
    public init(message: [String: Any]) {
        self.message = message
    }
    
    public override var description: String {
        get {
            return "Reply : \(message)"
        }
    }
}

@objc public protocol LinkDelegate {
    func didReceive(event: Event)
    func didConnect(module: DriverModule)
    func didDisconnect(module: DriverModule)
    func didFail(module: DriverModule)
}

@objc public class LinkProfile: NSObject {
    public let module: DriverModule
    public let app2appURL: String
    public let sslConfiguration: SSLConfiguration?
    public init(module: DriverModule, app2appURL: String, sslConfiguration: SSLConfiguration?) {
        self.module = module
        self.app2appURL = app2appURL
        self.sslConfiguration = sslConfiguration
    }
}

@objc public protocol Link {
    var profile: LinkProfile { get }
    var delegate: LinkDelegate? { get }
    init(withDelegate delegate: LinkDelegate?, andProfile profile: LinkProfile)
    func connect()
    func disconnect()
    func send(payload: Command, forDomain domain: String, onSuccess: @escaping (CommandReply) -> Void, onError: @escaping (NSError?) -> Void)
}
