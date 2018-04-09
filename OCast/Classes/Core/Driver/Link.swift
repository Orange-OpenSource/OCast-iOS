//
//  Link.swift
//  OCast
//
//  Created by Christophe Azemar on 04/04/2018.
//

import Foundation

// Used for Event messages
@objc public class Event: NSObject {
    public let domain: String
    public var message: [String: Any]
    public init(domain: String, message: [String: Any]) {
        self.domain = domain
        self.message = message
    }
}

@objc public class Command: NSObject {
    public let command: String
    public var params: [String: Any]
    public init(command: String = "", params: [String: Any]) {
        self.command = command
        self.params = params
    }
}

@objc public class CommandReply: NSObject {
    public let command: String
    public var reply: Any?
    public init(command: String = "", reply: Any?) {
        self.command = command
        self.reply = reply
    }
}

@objc public protocol LinkDelegate {
    func onEvent(payload: Event)
    func onLinkConnected(from identifier: Int8)
    func onLinkDisconnected(from identifier: Int8)
    func onLinkFailure(from identifier: Int8)
}

@objc public protocol LinkFactory {
    static func make(from sender: LinkDelegate, linkProfile: LinkProfile) -> LinkFactory
}

@objc public class LinkProfile: NSObject {
    public let identifier: Int8
    public let ipAddress: String
    public let needsEvent: Bool
    public let app2appURL: String
    public let certInfo: CertificateInfo?
    public init(identifier: Int8, ipAddress: String, needsEvent: Bool, app2appURL: String, certInfo: CertificateInfo?) {
        self.identifier = identifier
        self.ipAddress = ipAddress
        self.needsEvent = needsEvent
        self.app2appURL = app2appURL
        self.certInfo = certInfo
    }
}
