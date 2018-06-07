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
@objc public protocol PublicSettingsEventDelegate {
    func didReceiveEvent(updateStatus: StatusInfo)
}

/// :nodoc:
@objc
public protocol PublicSettings {
    var publicSettingsEventDelegate:PublicSettingsEventDelegate? { get set }
    // Receive event settings
    func didReceivePublicSettingsEvent(withMessage message: [String: Any])
    // Device settings
    func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void)
    func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
}

public struct PublicSettingsConstants {
    public static let COMMAND_STATUS = "getUpdateStatus"
    public static let COMMAND_DEVICE_ID = "getDeviceID"
    public static let SERVICE_SETTINGS_DEVICE = "org.ocast.settings.device"
    public static let EVENT_STATUS = "updateStatus"
}

extension PublicSettings {
    public func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
}

// MARK: - PrivateSettings protocol
@objc public protocol PrivateSettingsEventDelegate {
    func didReceiveEvent(connectionStatus: String)
    func didReceiveEvent(bluetoothDeviceInfo: BluetoothDevice)
    func didReceiveEvent(bluetoothKeyPressed: String)
    func didReceiveEvent(bluetoothMouseMovedToPositionX x: Int, andY y: Int)
    func didReceiveEvent(blueetoothMouseClicked: String)
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
    func sendCommand(name: String, macAddress: String, onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
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
    public func sendCommand(name: String, macAddress: String, onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
    public func sendPinCode(code: String, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        onError(NSError(domain: "OCast", code: 0, userInfo: ["Error": "Not implemented"]))
    }
}
