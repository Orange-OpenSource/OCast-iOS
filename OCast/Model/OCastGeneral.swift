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
//
//  OCastGeneral.swift
//  OCast
//
//  Created by Christophe Azemar on 16/11/2018.
//  Copyright © 2018 Orange. All rights reserved.
//

import DynamicCodable
import Foundation

/// The OCast errors.
///
/// - wrongStateDisconnected: The operation can be performed because the device is disconnected.
/// - wrongStateConnecting: The operation can be performed because the device is connecting.
/// - wrongStateConnected: The operation can be performed because the device is connected.
/// - wrongStateDisconnecting: The operation can be performed because the device is disconnecting.
/// - applicationNameNotSet: The operation can be performed because the application name is not set.
/// - badApplicationURL: The operation can be performed because the application URL is misformed.
/// - websocketConnectionEventNotReceived: The application has not sent the websocket connection event.
/// - emptyReplyReceived: An empty reply has been received.
/// - misformedCommand: The command is misformed and can't be sent.
/// - unableToSendCommand: The command has not been sent.
/// - transportError: A transport error occurs.
/// - wrongStateDisconnected: The command can't be sent because the device is disconnected.
@objc
public enum OCastError: Int, Error {
    case wrongStateDisconnected
    case wrongStateConnecting
    case wrongStateConnected
    case wrongStateDisconnecting
    case applicationNameNotSet
    case dialError
    case badApplicationURL
    case websocketConnectionEventNotReceived
    case emptyReplyReceived
    case badReplyFormatReceived
    case misformedCommand
    case unableToSendCommand
    case transportError
    case deviceHasBeenDisconnected
    case webSocketConnectionFailed
    case webSocketDisconnectionFailed
}

/// Due to Objective-C restrictions (lack of enumeration with associated value),
/// this struct is used to store the application layer code when an error occurs.
struct OCastReplyError: Error {
    let code: Int
}

/// The OCast transport errors.
public let OCastTransportErrors = [
    "json_format_error": "There is an error in the JSON formatting",
    "value_format_error": "This is an error in the packet, typically caused by a malformatted value",
    "missing_mandatory_field": "This is an error in the packet, typically caused by missing a field",
    "internal_error": "All other cases",
    "forbidden_unsecure_mode": "Packet has no right to access the required destination or service."
]

/// The base OCast message.
public typealias OCastMessage = NSObject & Codable

/// The domain name.
///
/// - browser: Browser.
/// - settings: Settings.
public enum OCastDomainName: String {
    case browser, settings
}

/// The device layer message type.
///
/// - command: Command message.
/// - reply: Reply message.
/// - event: Event message.
public enum OCastDeviceLayerType: String, Codable {
    case command, reply, event
}

/// The OCast status used only for reply messages.
///
/// - ok: The command successed.
/// - error: The command failed (with the string error).
public enum OCastStatusType: Codable, Equatable {
    case ok, error(String)
    
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self).lowercased()
        
        if value == "ok" {
            self = .ok
        } else {
            self = .error(OCastTransportErrors[value] ?? "unknown transport error")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
    
    public static func == (lhs: OCastStatusType, rhs: OCastStatusType) -> Bool {
        switch (lhs, rhs) {
        case (.ok, .ok):
            return true
        case (let .error(lhsErrorMessage), let .error(rhsErrorMessage)):
            return lhsErrorMessage == rhsErrorMessage
        default:
            return false
        }
    }
}

/// The OCast device layer.
public class OCastDeviceLayer<T: Codable>: OCastMessage {
    
    /// The message identifier.
    public let id: Int
    
    /// The sender.
    public let source: String
    
    /// The recipient.
    public let destination: String
    
    /// The message status (only for reply). See `OCastStatusType`
    public let status: OCastStatusType?
    
    /// The message type. See `OCastStatusType`
    public let type: OCastDeviceLayerType
    
    /// The message
    public let message: OCastApplicationLayer<T>
    
    private enum CodingKeys: String, CodingKey {
        case source = "src", destination = "dst", id, status, type, message
    }
    
    public init(source: String, destination: String, id: Int, status: OCastStatusType?, type: OCastDeviceLayerType, message: OCastApplicationLayer<T>) {
        self.source = source
        self.destination = destination
        self.id = id
        self.status = status
        self.type = type
        self.message = message
    }
    
    public convenience init(source: String, destination: String, id: Int, status: OCastStatusType?, type: OCastDeviceLayerType, service: String, name: String, params: T) {
        self.init(source: source, destination: destination, id: id, status: status, type: type, service: service, name: name, params: params, options: nil)
    }
    
    public convenience init(source: String, destination: String, id: Int, status: OCastStatusType?, type: OCastDeviceLayerType, service: String, name: String, params: T, options: [String: Any]?) {
        let reference = OCastDataLayer(name: name, params: params, options: options)
        let application = OCastApplicationLayer(service: service, data: reference)
        self.init(source: source, destination: destination, id: id, status: status, type: type, message: application)
    }
}

/// The OCast application layer.
public class OCastApplicationLayer<T: Codable>: OCastMessage {
    
    /// The service name.
    public let service: String
    
    /// The message data.
    public let data: OCastDataLayer<T>
    
    public init(service: String, data: OCastDataLayer<T>) {
        self.service = service
        self.data = data
    }
}

/// The OCast data layer.
public class OCastDataLayer<T: Codable>: OCastMessage {
    
    /// The name of the message.
    public let name: String?
    
    /// The parameters (must be Codable).
    public let params: T
    
    /// The options dictionary to add for example metadata.
    public let options: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case name, params, options
    }
    
    public init(name: String, params: T, options: [String: Any]? = nil) {
        self.name = name
        self.params = params
        self.options = options
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        params = try values.decode(T.self, forKey: .params)
        options = try values.decodeIfPresent([String: Any].self, forKey: .options)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(params, forKey: .params)
        try container.encodeIfPresent(options, forKey: .options)
    }
}

/// The default response containing the code.
public class OCastDefaultResponseDataLayer: OCastMessage {
    
    /// The code.
    public let code: Int?
    
    /// The success code.
    static let successCode = 0
}

/// A codable struct to manage commands without result.
struct NoResult: Codable {}
