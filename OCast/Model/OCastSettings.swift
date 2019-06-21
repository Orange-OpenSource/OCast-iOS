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

/// The device setttings service name.
public let OCastDeviceSettingsServiceName = "org.ocast.settings.device"

/// The input setttings service name.
public let OCastInputSettingsServiceName = "org.ocast.settings.input"

/// The notification sent when an update status event is received.
/// The userinfo `UpdateStatusUserInfoKey` key contains update status information.
public let UpdateStatusEventNotification = Notification.Name("UpdateStatusEvent")

/// The notification user info key representing the update status.
public let UpdateStatusUserInfoKey = Notification.Name("UpdateStatusKey")

// MARK: - Settings objects

/// The update status state.
///
/// - notChecked: The firmware version is not check yet.
/// - upToDate: The firmware version is up to date.
/// - newVersionFound: A new firmware version is available.
/// - newVersionReady: A new firmware is ready to be installed.
/// - downloading: A firmware version is downloading.
/// - error: An error occurs during the firmware update.
/// - success: The firmware update has ended with success.
@objc
public enum UpdateStatusState: Int, RawRepresentable, Codable {
    case notChecked, upToDate, newVersionFound, newVersionReady, downloading, error, success
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
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
        switch rawValue {
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

/// The update status.
@objc
public class SettingsUpdateStatus: OCastMessage {
    
    /// The state. See `UpdateStatusState`
    public let state: UpdateStatusState
    
    /// The version.
    public let version: String?
    
    /// The percentage downloaded.
    public let progress: Int
}

/// The device identifier.
@objc
public class SettingsDeviceID: OCastMessage {
    
    /// The identifier.
    public let id: String
}

/// The input gamepad axes.
@objc
public class InputGamepadAxes: OCastMessage {
    
    /// The x axis (-1.0 -> 1.0).
    public let x: Float
    
    /// The y axis (-1.0 -> 1.0).
    public let y: Float
    
    public let num: Int
}

// MARK: - Settings Commands

/// The update status command.
@objc public class SettingsGetUpdateStatusCommand: OCastMessage {}

/// The device id command.
@objc public class SettingsGetDeviceIDCommand: OCastMessage {}

/// The location of a key.
///
/// - standard: The key is not pressed on the right or left side of the keyboard, nor the numeric keypad.
/// - left: A left key is pressed.
/// - right: A right key is pressed.
/// - numpad: The key is pressed on the numeric keypad.
/// - mobile: The key is pressed on a mobile device.
/// - joystick: The key is pressed on a joystick.
@objc
public enum DOMKeyLocation: Int, Codable {
    case standard = 0
    case left = 1
    case right = 2
    case numpad = 3
    case mobile = 4
    case joystick = 5
}

/// The command to send a key.
@objc
public class SettingsKeyPressedCommand: OCastMessage {
    
    /// The key value.
    public let key: String
    
    /// The  code value of the physical key.
    public let code: String
    
    /// `true` if the control key is pressed.
    public let ctrl: Bool
    
    /// `true` if the alt key is pressed.
    public let alt: Bool
    
    /// `true` if the shift key is pressed.
    public let shift: Bool
    
    /// `true` if the meta key is pressed.
    public let meta: Bool
    
    /// The location.
    public let location: DOMKeyLocation
}

/// The command to send a mouse event.
@objc
public class SettingsMouseEventCommand: OCastMessage {
    
    /// The x coordinate of the mouse pointer in local coordinates.
    public let x: Int
    
    /// The y coordinate of the mouse pointer in local coordinates.
    public let y: Int
    
    /// The buttons pressed.
    /// Several buttons can be pressed at the same time by providing the bitmask representation of each button
    /// (0 no button, 1, 2 and 4 at least)
    public let buttons: Int
}

/// The command to send a gamepad event.
@objc
public class SettingsGamepadEventCommand: OCastMessage {
    
    /// The axes.
    public let axes: [InputGamepadAxes]
    
    /// The buttons pressed.
    /// Several buttons can be pressed at the same time by providing the bitmask representation of each button
    /// (0 no button, 1, 2 and 4 at least)
    public let buttons: Int
}

// MARK: - Settings error codes

/// The device settings errors.
///
/// - unknownError: An unknown error occurs.
@objc
public enum OCastDeviceSettingsError: Int, Error {
    case unknownError = 1199
}
