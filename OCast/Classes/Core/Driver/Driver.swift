//
// Driver.swift
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

// MARK: - Public Driver protocols
/// :nodoc:
public protocol DriverPublicSettings {
    // Not yet implemented on stick side. This getUpdateStatus() is given as an example.
    func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void)
    func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ())
}

extension DriverPublicSettings {
    public func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {}
    public func getDeviceID(onSuccess:@escaping (String) -> (), onError:@escaping (NSError?) -> ()) {}
}

/// :nodoc:
public protocol DriverPrivateSettings {
    // Network
    func scanAPs(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func getAPList(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
    func setAP(ssid: String, bssid: String, security: Int, password: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func remAP(ssid: String, onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func pbWPS(onSuccess: @escaping () -> (), onError:@escaping (NSError?) -> ())
    func getWifiInfo(onSuccess:@escaping ([WifiInfo]) -> (), onError:@escaping (NSError?) -> ())
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

extension DriverPrivateSettings {
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

// MARK: - Internal Driver protocols
/// :nodoc:
@objc public protocol DriverFactory: class {
    func make(for ipAddress: String, with certificateInfo: CertificateInfo?) -> Driver
}

// MARK: - Driver states
/// :nodoc:
@objc public enum DriverState:Int {
    case connecting = 0
    case connected
    case disconnecting
    case disconnected
}
/// :nodoc:
@objc public enum DriverModule:Int {
    case application = 0
    case privateSettings
    case publicSettings
}

@objc public protocol DriverDelegate {
    func onFailure(error: NSError?)
}

/// :nodoc:
@objc public protocol DriverReceiverDelegate {
    func onData(with data: [String: Any])
}

/// :nodoc:
@objc public protocol Driver: BrowserDelegate {
    var delegate: DriverReceiverDelegate? { get set }
    func privateSettingsAllowed() -> Bool
    func connect(for module: DriverModule, with info: ApplicationDescription, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func getState(for module: DriverModule) -> DriverState
    func register(_ delegate: DriverDelegate, forModule module: DriverModule)
}





