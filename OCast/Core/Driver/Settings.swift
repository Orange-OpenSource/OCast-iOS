//
// Settings.swift
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

// MARK: - PublicSettings protocol

/// The delegate of a PublicSettings object must adopt the PublicSettingsEventDelegate protocol in order to receive public setting events.
@objc public protocol PublicSettingsEventDelegate {
    
    /// Tells the delegate that the publicsettings has received a status event.
    ///
    /// - Parameters:
    ///   - publicSettings: The `PublicSettings` instance.
    ///   - updateStatus: The `StatusInfo`object containing status information.
    func publicSettings(_ publicSettings: PublicSettings, didReceiveUpdateStatus updateStatus: StatusInfo)
}

/// :nodoc:
@objc
public protocol PublicSettings {
    var publicSettingsEventDelegate:PublicSettingsEventDelegate? { get set }
    // Receive event settings
    func didReceivePublicSettingsEvent(withMessage message: [String: Any])
    /// Return information about update status of stick.
    ///
    /// - Parameters:
    ///   - onSuccess: called when request is success.
    ///   - onError: called when an error occured.
    func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void)
    /// Return the device's id.
    ///
    /// - Parameters:
    ///   - onSuccess: called when request success.
    ///   - onError: called when an error occured.
    func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
    /// Virtual key pressed
    ///
    /// - Parameters:
    ///   - key: key value
    ///   - onSuccess: called when request success.
    ///   - onError: called when an error occured.
    func keyPressed(key: KeyValue, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ())
    /// send a mouse event
    ///
    /// - Parameters:
    ///   - x: x
    ///   - y: y
    ///   - buttons: buttons
    ///   - onSuccess: called when request success.
    ///   - onError: called when an error occured.
    func mouseEvent(x: Int, y: Int, buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ())
    /// send a gamepad event
    ///
    /// - Parameters:
    ///   - axes: list of axes
    ///   - buttons: buttons
    ///   - onSuccess: called when request success.
    ///   - onError: called when an error occured.
    func gamepadEvent(axes: [GamepadAxes], buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ())
}

public struct PublicSettingsConstants {
    public static let COMMAND_STATUS = "getUpdateStatus"
    public static let COMMAND_DEVICE_ID = "getDeviceID"
    public static let COMMAND_KEY_PRESSED = "keyPressed"
    public static let COMMAND_MOUSE_EVENT = "mouseEvent"
    public static let COMMAND_GAMEPAD_EVENT = "gamepadEvent"
    public static let SERVICE_SETTINGS_DEVICE = "org.ocast.settings.device"
    public static let SERVICE_SETTINGS_INPUT = "org.ocast.settings.input"
    public static let EVENT_STATUS = "updateStatus"
}

extension PublicSettings {
    public func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func keyPressed(key: KeyValue, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func mouseEvent(x: Int, y: Int, buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func gamepadEvent(axes: [GamepadAxes], buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
}

// MARK: - PrivateSettings protocol

/// The delegate of a PrivateSettings object must adopt the PrivateSettingsEventDelegate protocol in order to receive private setting events.
@objc public protocol PrivateSettingsEventDelegate {
    
    /// Tells the delegate that the privatesettings has received a WiFi status event.
    ///
    /// - Parameters:
    ///   - privateSettings: The `PrivateSettings` instance.
    ///   - wifiStatus: The `WifiStatus` object containing Wifi information.
    func privateSettings(_ privateSettings: PrivateSettings, didReceiveWifiConnectionStatus wifiStatus: WifiStatus)
    
    /// Tells the delegate that the privatesettings has received a device info event.
    ///
    /// - Parameters:
    ///   - privateSettings: The `PrivateSettings` instance.
    ///   - bluetoothDevice: The `BluetoothDevice` object containing device information.
    func privateSettings(_ privateSettings: PrivateSettings, didReceiveBluetoothDeviceInfo bluetoothDevice: BluetoothDevice)
    
    /// Tells the delegate that the privatesettings has received a bluetooth keyboard event.
    ///
    /// - Parameters:
    ///   - privateSettings: The `PrivateSettings` instance.
    ///   - key: The key typed by the user.
    func privateSettings(_ privateSettings: PrivateSettings, didReceiveBluetoothKeyPressed key: String)
    
    /// Tells the delegate that the privatesettings has received a bluetooth mouse position event.
    ///
    /// - Parameters:
    ///   - privateSettings: The `PrivateSettings` instance.
    ///   - x: The mouse x position.
    ///   - y: The mouse y position.
    func privateSettings(_ privateSettings: PrivateSettings, didReceiveBluetoothMouseMovedToX x: Int, Y y: Int)
    
    /// Tells the delegate that the privatesettings has received a bluetooth mouse click event.
    ///
    /// - Parameters:
    ///   - privateSettings: The `PrivateSettings` instance.
    ///   - key: The button clicked by the user.
    func privateSettings(_ privateSettings: PrivateSettings, didReceiveBlueetoothMouseClicked key: String)
}

@objc
public protocol PrivateSettings {
    var privateSettingsEventDelegate: PrivateSettingsEventDelegate? { get set }
    // Receive event settings
    func didReceivePrivateSettingsEvent(withMessage message: [String: Any])
    // Network
    func scanAPs(pinCode: Int, onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func getAPList(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func setAP(pinCode: Int, ssid: String, bssid: String, security: Int, password: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func remAP(ssid: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func pbWPS(pinCode: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getWifiInfo(onSuccess:@escaping (WifiInfo) -> (), onError:@escaping (NSError?) -> ())
    func getNetworkInfo(onSuccess:@escaping (NetworkInfo) -> (), onError:@escaping (NSError?) -> ())
    func getAPPinCode(onSuccess: @escaping (Int) -> (), onError: @escaping (NSError?) -> ())
    // Device
    func setDevice(name: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getInfo(onSuccess:@escaping (VersionInfo) -> (), onError:@escaping (NSError?) -> ())
    func reboot(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getDeviceInfo(onSuccess:@escaping (DeviceInfo) -> (), onError:@escaping (NSError?) -> ())
    func reset(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func checkStick(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    // bluetooth
    func startDiscovery(profiles: [String], timeout: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func stopDiscovery(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getDevices(profiles: [String], onSuccess:@escaping ([BluetoothDevice]) -> (), onError:@escaping (NSError?) -> ())
    func sendCommand(type: BluetoothCommandType, macAddress: String, onSuccess:@escaping (BluetoothDeviceState) -> (), onError:@escaping (NSError?) -> ())
    func sendPinCode(code: String, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ())
}

extension PrivateSettings {
    // Network
    public func scanAPs(pinCode: Int, onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getAPList(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func setAP(pinCode: Int, ssid: String, bssid: String, security: Int, password: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func remAP(ssid: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func pbWPS(pinCode: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getWifiInfo(onSuccess:@escaping (WifiInfo) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getNetworkInfo(onSuccess:@escaping (NetworkInfo) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    func getAPPinCode(onSuccess: @escaping (Int) -> (), onError: @escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    // Device
    public func setDevice(name: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getInfo(onSuccess:@escaping (VersionInfo) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func reboot(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getDeviceInfo(onSuccess:@escaping (DeviceInfo) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func reset(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func checkStick(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    // bluetooth
    public func startDiscovery(profiles: [String], timeout: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func stopDiscovery(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getDevices(profiles: [String], onSuccess:@escaping ([BluetoothDevice]) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func sendCommand(type: BluetoothCommandType, macAddress: String, onSuccess:@escaping (BluetoothDeviceState) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func sendPinCode(code: String, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
}
