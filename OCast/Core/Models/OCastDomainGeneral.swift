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
//  OCastDomain.swift
//  OCast
//
//  Created by Christophe Azemar on 16/11/2018.
//  Copyright © 2018 Orange. All rights reserved.
//

import DynamicCodable
import Foundation

@objc
public enum OCastError: Int, Error {
    case wrongStateDisconnected
    case wrongStateConnecting
    case wrongStateConnected
    case wrongStateDisconnecting
    case applicationNameNotSet
    case badApplicationURL
    case websocketConnectionEventNotReceived
    case badReplyFormatReceived
    case misformedCommand
    case transportError
    case deviceHasBeenDisconnected
}

/// Due to Objective-C restrictions (lack of enumeration with associated value),
/// this struct is used to store the application layer code when an error occurs.
struct OCastReplyError: Error {
    let code: Int
}

public let OCastDeviceDisconnectedEventNotification = Notification.Name("OCastDeviceDisconnectedEvent")
public let OCastDeviceUserInfoKey = Notification.Name("OCastDeviceKey")

public let OCastTransportErrors = [
    "json_format_error": "There is an error in the JSON formatting",
    "value_format_error": "This is an error in the packet, typically caused by a malformatted value",
    "missing_mandatory_field": "This is an error in the packet, typically caused by missing a field",
    "internal_error": "All other cases",
    "forbidden_unsecure_mode": "Packet has no right to access the required destination or service."
]

public typealias OCastMessage = NSObject & Codable

public enum OCastDomainName: String {
    case browser = "browser"
    case settings = "settings"
    case all = "*"
}

enum OCastDeviceLayerType: String, Codable {
    case command, reply, event
}

enum StatusType: Codable, Equatable {
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
    
    public static func == (lhs: StatusType, rhs: StatusType) -> Bool {
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

class OCastDeviceLayer<T: Codable>: OCastMessage {
    public let id: Int
    public let source: String
    public let destination: String
    public let status: StatusType?
    public let type: OCastDeviceLayerType
    public let message: OCastApplicationLayer<T>
    
    private enum CodingKeys : String, CodingKey {
        case source = "src", destination = "dst", id, status, type, message
    }
    
    init(source: String, destination: String, id: Int, status: StatusType?, type: OCastDeviceLayerType, message: OCastApplicationLayer<T>) {
        self.source = source
        self.destination = destination
        self.id = id
        self.status = status
        self.type = type
        self.message = message
    }
    
    convenience init(source: String, destination: String, id: Int, status: StatusType?, type: OCastDeviceLayerType, service: String, name: String, params: T) {
        self.init(source: source, destination: destination, id: id, status: status, type: type, service: service, name: name, params: params, options: nil)
    }
    
    convenience init(source: String, destination: String, id: Int, status: StatusType?, type: OCastDeviceLayerType, service: String, name: String, params: T, options: [String: Any]?) {
        let reference = OCastDataLayer(name: name, params: params, options: options)
        let application = OCastApplicationLayer(service: service, data: reference)
        self.init(source: source, destination: destination, id: id, status: status, type: type, message: application)
    }
}

public class OCastApplicationLayer<T: Codable>: OCastMessage {
    public let service: String
    public let data: OCastDataLayer<T>
    
    public init(service: String, data: OCastDataLayer<T>) {
        self.service = service
        self.data = data
    }
}

public class OCastDataLayer<T: Codable>: OCastMessage {
    public let name: String?
    public let params: T
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

// Default Response is containing code property for every command.
@objc
class OCastDefaultResponseDataLayer: OCastMessage {
    public let code: Int?
    static let successCode = 0
}

struct NoResult: Decodable {}
