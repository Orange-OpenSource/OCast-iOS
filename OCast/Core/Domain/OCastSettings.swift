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
//  OCastSettings.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

/// The device setttings service name
public let OCastDeviceSettingsServiceName = "org.ocast.settings.device"

/// The input setttings service name
public let OCastInputSettingsServiceName = "org.ocast.settings.input"

public let OCastUpdateStatusEventNotification = Notification.Name("OCastFirmwareUpdateEvent")
public let OCastUpdateStatusUserInfoKey = Notification.Name("OCastUpdateStatusKey")

// MARK: - Settings objects

@objc
public enum UpdateStatusState: Int, RawRepresentable, Codable {
    
    public typealias RawValue = String
    
    case notChecked
    case upToDate
    case newVersionFound
    case newVersionReady
    case downloading
    case error
    case success
    
    public var rawValue: RawValue {
        switch (self) {
        case .notChecked: return "notChecked"
        case .upToDate: return "upToDate"
        case .newVersionFound: return "newVersionFound"
        case .newVersionReady: return "newVersionReady"
        case .downloading: return "downloading"
        case .error: return "error"
        case .success: return "success"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch (rawValue) {
        case "notChecked": self = .notChecked
        case "upToDate": self = .upToDate
        case "newVersionFound": self = .newVersionFound
        case "newVersionReady": self = .newVersionReady
        case "downloading": self = .downloading
        case "error": self = .error
        case "success": self = .success
        default: return nil
        }
    }
}

@objc
public class SettingsUpdateStatus: OCastMessage {
    public let state: UpdateStatusState
    // TODO: check if optional
    public let version: String?
    public let progress: Int
}

@objc
public class SettingsDeviceID: OCastMessage {
    public let id: String
}

@objc
public class InputGamepadAxes: OCastMessage {
    public let x: Float
    public let y: Float
    public let num : Int
}

// MARK: - Settings Commands

@objc public class SettingsGetUpdateStatusCommand: OCastMessage {}
@objc public class SettingsGetDeviceIDCommand: OCastMessage {}

@objc
public enum DOMKeyLocation: Int, Codable {
    case standard = 0
    case left = 1
    case right = 2
    case numpad = 3
    case mobile = 4
    case joystick = 5
}

@objc
public class SettingsKeyPressedCommand: OCastMessage {
    public let key: String
    public let code: String
    public let ctrl: Bool
    public let alt: Bool
    public let shift: Bool
    public let meta: Bool
    public let location: DOMKeyLocation
}

@objc
public class SettingsMouseEventCommand: OCastMessage {
    public let x: Int
    public let y: Int
    public let buttons: Int
}

@objc
public class SettingsGamepadEventCommand: OCastMessage {
    public let axes: [InputGamepadAxes]
    public let buttons: Int
}

@objc public enum OCastDeviceSettingsError: Int, Error {
    case unknownError = 1199
}
