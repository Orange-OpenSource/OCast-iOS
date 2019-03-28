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

import Foundation
import DynamicCodable

public let OCastErrorDomain = "OCastError"

public let kOCastPlaybackStatusEvent = "OCastPlaybackStatusEvent"
public let kOCastMetadataChangedEvent = "OCastMetadataChangedEvent"
public let kOCastFirmwareUpdateEvent = "OCastFirmwareUpdateEvent"
public let kOCastCustomEvent = "OCastCustomEvent"

public let OCastPlaybackStatusEventNotification = Notification.Name(kOCastPlaybackStatusEvent)
public let OCastMetadataChangedEventNotification = Notification.Name(kOCastMetadataChangedEvent)
public let OCastUpdateStatusEventNotification = Notification.Name(kOCastFirmwareUpdateEvent)
public let OCastCustomEventNotification = Notification.Name(kOCastCustomEvent)

public let OCastTransportErrors = [
    "json_format_error": "There is an error in the JSON formatting",
    "value_format_error": "This is an error in the packet, typically caused by a malformatted value",
    "missing_mandatory_field": "This is an error in the packet, typically caused by missing a field",
    "internal_error": "All other cases",
    "forbidden_unsecure_mode": "Packet has no right to access the required destination or service."
]

public typealias OCastMessage = NSObject & Codable

/// Describes a Device
@objcMembers
@objc public final class Device: NSObject {
    /// base URL of the device
    public let baseURL: URL
    /// IP address
    public let ipAddress: String
    /// service port
    public let servicePort: UInt16
    /// unique device ID (aka USN)
    public let deviceID: String
    /// friendly name
    public let friendlyName: String
    /// manufacturer's name
    public let manufacturer: String
    /// model name
    public let modelName: String
    
    
    /// Create a Device
    ///
    /// - Parameters:
    ///   - baseURL: baseURL of the device
    ///   - ipAddress: IP address
    ///   - servicePort: service port
    ///   - deviceID: unique device ID (aka USN)
    ///   - friendlyName: friendly name
    ///   - manufacturer: manufacturer's name
    ///   - modelName: model name
    init(baseURL: URL, ipAddress: String, servicePort: UInt16, deviceID: String, friendlyName: String, manufacturer: String, modelName: String) {
        self.baseURL = baseURL
        self.ipAddress = ipAddress
        self.servicePort = servicePort
        self.deviceID = deviceID
        self.friendlyName = friendlyName
        self.manufacturer = manufacturer
        self.modelName = modelName
    }
}

public enum OCastDomainName: String {
    case browser = "browser"
    case settings = "settings"
    case all = "*"
}

public protocol OCastDeviceLayer {
    associatedtype OCastDeviceMessageType: OCastApplicationLayer
    var id: Int { get }
    var source: String { get }
    var destination: String { get }
    var status: String? { get }
    var type: String { get }
    var message: OCastDeviceMessageType { get }
}

public protocol OCastApplicationLayer {
    associatedtype OCastApplicationDataType: OCastDataLayer
    var service: String { get }
    var data: OCastApplicationDataType { get }
}

public protocol OCastDataLayer {
    associatedtype OCastDataParamsType
    var name: String? { get }
    var params: OCastDataParamsType { get }
    var options: [String: Any]? { get }
}

public class OCastGenericDeviceLayer<T: Codable>: OCastMessage, OCastDeviceLayer {
    public typealias OCastDeviceMessageType = OCastGenericApplicationLayer<T>
    public let id: Int
    public let source: String
    public let destination: String
    public let status: String?
    public let type: String
    public let message: OCastGenericApplicationLayer<T>
    
    private enum CodingKeys : String, CodingKey {
        case source = "src", destination = "dst", id, status, type, message
    }
    
    public init(source: String, destination: String, id: Int, status: String?, type: String, message: OCastGenericApplicationLayer<T>) {
        self.source = source
        self.destination = destination
        self.id = id
        self.status = status
        self.type = type
        self.message = message
    }
    
    public convenience init(source: String, destination: String, id: Int, status: String?, type: String, service: String, name: String, params: T) {
        self.init(source: source, destination: destination, id: id, status: status, type: type, service: service, name: name, params: params, options: nil)
    }
    
    public convenience init(source: String, destination: String, id: Int, status: String?, type: String, service: String, name: String, params: T, options: [String: Any]?) {
        let reference = OCastGenericDataLayer(name: name, params: params, options: options)
        let application = OCastGenericApplicationLayer(service: service, data: reference)
        self.init(source: source, destination: destination, id: id, status: status, type: type, message: application)
    }
}

public class OCastGenericApplicationLayer<T: Codable>: OCastMessage, OCastApplicationLayer {
    public typealias OCastApplicationDataType = OCastGenericDataLayer
    public let service: String
    public let data: OCastGenericDataLayer<T>
    
    public init(service: String, data: OCastGenericDataLayer<T>) {
        self.service = service
        self.data = data
    }
}

public class OCastGenericDataLayer<T: Codable>: OCastMessage, OCastDataLayer {
    public typealias OCastDataParamsType = T
    public let name: String?
    public let params: T
    public let options: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case name, params, options
    }
    
    public init(name: String, params: T, options: [String: Any]?) {
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

@objc
public class OCastDefaultDataParams: OCastMessage {
    public let code: Int?
}

public class OCastCustomDeviceLayer: OCastMessage, OCastDeviceLayer {
    public typealias OCastDeviceMessageType = OCastCustomApplicationLayer
    public let source: String
    public let destination: String
    public let id: Int
    public let status: String?
    public let type: String
    public let message: OCastCustomApplicationLayer
    
    private enum CodingKeys : String, CodingKey {
        case source = "src", destination = "dst", id, status, type, message
    }
    
    public init(source: String, destination: String, id: Int, status: String?, type: String, message: OCastCustomApplicationLayer) {
        self.source = source
        self.destination = destination
        self.id = id
        self.status = status
        self.type = type
        self.message = message
    }
}

public class OCastCustomApplicationLayer: OCastMessage, OCastApplicationLayer {
    public typealias OCastApplicationDataType = OCastCustomDataLayer
    public let service: String
    public let data: OCastCustomDataLayer
    
    public init(service: String, data: OCastCustomDataLayer) {
        self.service = service
        self.data = data
    }
}

@objc
@objcMembers
public class OCastCustomDataLayer: OCastMessage, OCastDataLayer {
    public typealias OCastDataParamsType = [String: Any]
    public let name: String?
    public let params: [String: Any]
    public let options: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case name, params, options
    }

    public init(name: String, params: [String: Any], options: [String: Any]?) {
        self.name = name
        self.params = params
        self.options = options
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        params = try values.decode([String: Any].self, forKey: .params)
        options = try values.decodeIfPresent([String: Any].self, forKey: .options)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(params, forKey: .params)
        try container.encodeIfPresent(options, forKey: .options)
    }
}
