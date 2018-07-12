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
    /// Init an event
    ///
    /// - Parameters:
    ///   - source: event's source
    ///   - message: event's message
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
    /// Init a command
    ///
    /// - Parameters:
    ///   - command: command's name
    ///   - params: command's parameters
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
    
    /// Init a Command's reply
    ///
    /// - Parameter message: reply's parameters
    public init(message: [String: Any]) {
        self.message = message
    }
    
    public override var description: String {
        get {
            return "Reply : \(message)"
        }
    }
}

/// Link's delegate
@objc public protocol LinkDelegate {
    
    /// Tells the delegate that the link has been connected.
    ///
    /// - Parameters:
    ///   - link: The link.
    func linkDidConnect(_ link: Link)
    
    /// Tells the delegate that the link has been disconnected.
    ///
    /// - Parameters:
    ///   - link: The link.
    ///   - error: The error.
    func link(_ link: Link, didDisconnectWith error: Error?)
    
    /// Tells the delegate that the link has received an event.
    ///
    /// - Parameters:
    ///   - link: The link.
    ///   - event: The event received.
    func link(_ link: Link, didReceiveEvent event: Event)
}

@objc public class LinkProfile: NSObject {
    public let app2appURL: String
    public let sslConfiguration: SSLConfiguration?
    public init(app2appURL: String, sslConfiguration: SSLConfiguration?) {
        self.app2appURL = app2appURL
        self.sslConfiguration = sslConfiguration
    }
}

@objc public protocol Link {
    var profile: LinkProfile { get }
    var delegate: LinkDelegate? { get }
    /// Init a link
    ///
    /// - Parameters:
    ///   - delegate: link's delegate
    ///   - profile: link's profile
    init(withDelegate delegate: LinkDelegate?, andProfile profile: LinkProfile)
    /// Connect the link
    func connect()
    /// Disconnect the link
    func disconnect()
    /// Send a command
    ///
    /// - Parameters:
    ///   - payload: payload to send
    ///   - domain: domain of the message
    ///   - onSuccess: called when payload has been sent correctly.
    ///   - onError: called when payload hasn's been sent.
    func send(payload: Command, forDomain domain: String, onSuccess: @escaping (CommandReply) -> Void, onError: @escaping (NSError?) -> Void)
}
