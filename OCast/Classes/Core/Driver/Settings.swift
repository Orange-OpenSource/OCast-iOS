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
public protocol PublicSettings {
    var publicSettingsEventDelegate:PublicSettingsEventDelegate? { get set }
    // Receive event settings
    func didReceivePublicSettingsEvent(withMessage message: [String: Any])
    // Device settings
    func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void)
    func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
}

struct PublicSettingsConstants {
    static let COMMAND_STATUS = "getUpdateStatus"
    static let COMMAND_DEVICE_ID = "getDeviceID"
    static let SERVICE_SETTINGS_DEVICE = "org.ocast.settings.device"
}

extension PublicSettings {
    public func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {}
    public func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {}
}

// MARK: - PrivateSettings protocol
@objc public protocol PrivateSettingsEventDelegate {
    func didReceiveEvent(connectionStatus: String)
    func didReceiveEvent(bluetoothDeviceInfo: String)
    func didReceiveEvent(bluetoothKeyPressed: String)
    func didReceiveEvent(bluetoothMouseMovedToPositionX x: Int, andY y: Int)
    func didReceiveEvent(blueetoothMouseClicked: String)
}

public protocol PrivateSettings {
    var privateSettingsEventDelegate: PrivateSettingsEventDelegate? { get set }
    // Receive event settings
    func didReceivePrivateSettingsEvent(withMessage message: [String: Any])
    // Network
    func scanAPs(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func getAPList(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func setAP(ssid: String, bssid: String, security: Int, password: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func remAP(ssid: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func pbWPS(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getWifiInfo(onSuccess:@escaping (WifiInfo) -> (), onError:@escaping (NSError?) -> ())
    func getNetworkInfo(onSuccess:@escaping (NetworkInfo) -> (), onError:@escaping (NSError?) -> ())
    // Device
    func setDevice(name: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getInfo(onSuccess:@escaping (VersionInfo) -> (), onError:@escaping (NSError?) -> ())
    func reboot(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getDeviceInfo(onSuccess:@escaping (DeviceInfo) -> (), onError:@escaping (NSError?) -> ())
    func reset(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func checkFlash(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    // bluetooth
    func startDiscovery(profiles: [String], timeout: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func stopDiscovery(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getDevices(profiles: [String], onSuccess:@escaping ([BluetoothDevice]) -> (), onError:@escaping (NSError?) -> ())
    func sendCommand(name: String, macAddress: String, onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
    func sendPinCode(code: String, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ())
}

extension PrivateSettings {
    // Network
    public func scanAPs(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ()) {}
    public func getAPList(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ()) {}
    public func setAP(ssid: String, bssid: String, security: Int, password: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func remAP(ssid: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func pbWPS(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func getWifiInfo(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ()) {}
    public func getNetworkInfo(onSuccess:@escaping (NetworkInfo) -> (), onError:@escaping (NSError?) -> ()) {}
    // Device
    public func setDevice(name: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func getInfo(onSuccess:@escaping (VersionInfo) -> (), onError:@escaping (NSError?) -> ()) {}
    public func reboot(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func getDeviceInfo(onSuccess:@escaping (DeviceInfo) -> (), onError:@escaping (NSError?) -> ()) {}
    public func reset(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func checkFlash(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    // bluetooth
    public func startDiscovery(profiles: [String], timeout: Int, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func stopDiscovery(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ()) {}
    public func getDevices(profiles: [String], onSuccess:@escaping ([BluetoothDevice]) -> (), onError:@escaping (NSError?) -> ()) {}
    public func sendCommand(name: String, macAddress: String, onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {}
    public func sendPinCode(code: String, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {}
}
