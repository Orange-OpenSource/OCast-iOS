//
// PrivateModels.swift
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
//

import Foundation

// MARK: - Internal Generic model structure


// Used to transfer data from/to the browser north interface
struct BrowserData {
    let service: String?
    let data: [String: Any]?
}

// Used by the MediaControler

extension MediaType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .image: return "image"
        case .video: return"video"
        }
    }
    
    init(type : String) {
        switch (type) {
        case "audio": self = .audio
        case "video": self = .video
        case "image": self = .image
        default: self = .audio
        }
    }
}

extension TransferMode {
    func toString() -> String {
        switch self {
        case .buffered: return "buffered"
        case .streamed: return "streamed"
        }
    }
}

extension MediaErrorCode {
    func toString() -> String {
        switch self {
        case .invalidService: return "invalidService"
        case .noImplementation: return "noImplementation"
        case .missingParameter: return "missingParameter"
        case .invalidPlayerState: return "invalidPlayerState"
        case .unknowMediaType: return "unknowMediaType"
        case .unknownTransferMode: return "unknownTransferMode"
        case .unknownError: return "unknownError"
        case .invalidTrack: return "invalidTtrack"
        case .noError: return"noError"
        default: return "Unvalid error code"
        }
    }
}

extension TrackType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .video: return "video"
        case .text: return "text"
        case .undefined: return "undefined"
        }
    }
}

@objcMembers
public final class WifiInfo: NSObject {
    public let ssid: String?
    public let bssid: String?
    public let frequency: Float?
    public let rssi: Int?
    public let security: Int?
    public let ip: String?
    public let macAddress: String?
    public let mode: String?
    
    public init (ssid: String?, bssid: String?, frequency: Float?, rssi: Int?, security: Int?, ip: String?, macAddress: String?, mode: String?) {
        self.ssid = ssid
        self.bssid = bssid
        self.frequency = frequency
        self.rssi = rssi
        self.security = security
        self.ip = ip
        self.macAddress = macAddress
        self.mode = mode
    }
}

/// :nodoc:
@objcMembers
@objc public final class NetworkInfo: NSObject {
    public let ipAddress: String?
    public let rate: Int?
    public let macAddress: String?
    
    public init(ipAddress: String?, rate: Int, macAddress: String?) {
        self.ipAddress = ipAddress
        self.rate = rate
        self.macAddress = macAddress
    }
}


@objcMembers
public final class VersionInfo: NSObject {
    public let name: String?
    public let softwareVersion: String?
    public let hardwareVersion: String?
    
    @objc public init(name: String?, softwareVersion: String?, hardwareVersion: String?) {
        self.name = name
        self.softwareVersion = softwareVersion
        self.hardwareVersion = hardwareVersion
    }
}

@objcMembers
public final class DeviceInfo: NSObject {
    public let vendor: String?
    public let model: String?
    public let serialNumber: String?
    public let macAddress: String?
    public let countryCode: String?
    
    @objc public init(vendor: String?, model: String?, serialNumber: String?, macAddress: String?, countryCode: String?) {
        self.vendor = vendor
        self.model = model
        self.serialNumber = serialNumber
        self.macAddress = macAddress
        self.countryCode = countryCode
    }
}

@objcMembers
public final class BluetoothDevice: NSObject {
    public let name: String?
    public let macAddress: String?
    public let cod: String?
    public let profiles: [String]?
    public let state: String?
    public let battery: Int
    public let version: String?
    
    @objc public init(name: String?, macAddress: String?, cod: String?, profiles: [String]?, state: String?, battery: Int, version: String?) {
        self.name = name
        self.macAddress = macAddress
        self.cod = cod
        self.profiles = profiles
        self.state = state
        self.battery = battery
        self.version = version
    }
}


