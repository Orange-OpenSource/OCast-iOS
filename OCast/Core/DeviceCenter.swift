//
// DeviceCenter.swift
//
// Copyright 2019 Orange
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

/// Protocol for responding to device discovery events.
@objc public protocol DeviceCenterDelegate {
    
    /// Tells the delegate that new devices are found.
    ///
    /// - Parameters:
    ///   - center: The device center informing the delegate.
    ///   - devices: The new devices found.
    func center(_ center: DeviceCenter, didAdd devices: [Device])
    
    /// Tells the delegate that devices are lost.
    ///
    /// - Parameters:
    ///   - center: The device center informing the delegate.
    ///   - devices: The devices lost.
    func center(_ center: DeviceCenter, didRemove devices: [Device])
    
    /// Tells the delegate that the discovery is stopped. All the devices are removed.
    ///
    /// - Parameters:
    ///   - center: The device center informing the delegate.
    ///   - error: The error if there's an issue, `nil` if the device discovery has been stopped normally.
    func centerDidStop(_ center: DeviceCenter, withError error: Error?)
}

/// The center which discover OCast devices on the network.
/// You must register a device for a manufacturer using the `registerDevice(_:forManufacturer:)` method.
/// Then you can start the discovery with the `resumeDiscovery` method.
/// If you want to release this object, you must call `stopDiscovery` before to avoid memory leaks.
@objcMembers
public class DeviceCenter: NSObject, DeviceDiscoveryDelegate {

    /// The registered devices saving the manufacturer and the device type.
    private var registeredDevices: [String: Device.Type] = [:]
    
    /// The search targets used to search the devices.
    private var searchTargets: [String] = []
    
    /// The discovered devices.
    private var discoveredDevices: [UPNPDevice: Device] = [:]
    
    /// The delegate to receive discovery events.
    private var deviceDiscovery: DeviceDiscovery?
    
    /// The delegate to receive the device center events.
    public weak var delegate: DeviceCenterDelegate?
    
    /// The interval in seconds to refresh the devices. The minimum value is 5 seconds.
    public var discoveryInterval: UInt16 {
        get { return deviceDiscovery?.interval ?? 0 }
        set { deviceDiscovery?.interval = newValue }
    }
    
    /// The devices discovered on the network.
    public var devices: [Device] {
        return Array(discoveredDevices.values)
    }
    
    /// Registers a device type to discover devices of its manufacturer.
    ///
    /// - Parameters:
    ///   - deviceType: The Type of the device class to register (for example ReferenceDevice.self)
    ///   - manufacturer: The device manufacturer used to identify it during the discovery.
    public func registerDevice(_ deviceType: Device.Type, forManufacturer manufacturer: String) {
        registeredDevices[manufacturer] = deviceType
        searchTargets.append(deviceType.searchTarget)
    }
    
    /// Resumes the discovery process to found devices on the local network.
    /// When a new devices are found the `deviceCenterAddDevicesNotification` notification
    /// and the `center(_:didAdd:)` method are triggered.
    /// When devices are lost the `deviceCenterRemoveDevicesNotification` notification
    /// and the `center(_:didRemove:)` method are triggered.
    ///
    /// - Returns: `true` if the discovery is correctly started, otherwise `false`.
    @discardableResult
    public func resumeDiscovery() -> Bool {
        // Initializes the device discovery with the drivers registered previously.
        if deviceDiscovery == nil {
            deviceDiscovery = DeviceDiscovery(searchTargets)
        }
        
        deviceDiscovery?.delegate = self
        return deviceDiscovery?.resume() ?? false
    }
    
    /// Stops the discovery process. The devices are removed so the `deviceCenterRemoveDevicesNotification`
    /// notification and the `center(_:didRemove:)` method will be triggered.
    /// This method will also trigger the `deviceCenterDiscoveryStoppedNotification` notification
    /// and the `centerDidStop(_:withError:)` method.
    ///
    /// - Returns: `true` if the discovery is correctly stopped, otherwise `false`.
    @discardableResult
    public func stopDiscovery() -> Bool {
        return deviceDiscovery?.stop() ?? false
    }
    
    /// Pauses the discovery process. The devices are not removed.
    ///
    /// - Returns: `true` if the discovery is correctly paused, otherwise `false`.
    @discardableResult
    public func pauseDiscovery() -> Bool {
        return deviceDiscovery?.pause() ?? false
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAdd devices: [UPNPDevice]) {
        var newDevices = [Device]()
        devices.forEach { device in
            if let type = registeredDevices[device.manufacturer] {
                    let ocastDevice = type.init(upnpDevice: device)
                    newDevices.append(ocastDevice)
                    discoveredDevices[device] = ocastDevice
            } else {
                Logger.shared.log(logLevel: .error,
                                  "Device \(device.friendlyName) found but manufacturer \(device.manufacturer) not registered")
            }
        }
        
        if !newDevices.isEmpty {
            delegate?.center(self, didAdd: newDevices)
            NotificationCenter.default.post(name: .deviceCenterAddDevicesNotification,
                                            object: self,
                                            userInfo: [DeviceCenterUserInfoKey.devicesUserInfoKey: newDevices])
        }
    }
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemove devices: [UPNPDevice]) {
        let removedDevices = devices.compactMap({ discoveredDevices[$0] })
        devices.forEach({ discoveredDevices.removeValue(forKey: $0) })
        delegate?.center(self, didRemove: removedDevices)
        NotificationCenter.default.post(name: .deviceCenterRemoveDevicesNotification,
                                        object: self,
                                        userInfo: [DeviceCenterUserInfoKey.devicesUserInfoKey: removedDevices])
    }
    
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, with error: Error?) {
        delegate?.centerDidStop(self, withError: error)
        
        var userInfo: [String: Any]?
        if let error = error {
            userInfo = [DeviceCenterUserInfoKey.errorUserInfoKey: error]
        }
        NotificationCenter.default.post(name: .deviceCenterDiscoveryStoppedNotification,
                                        object: self,
                                        userInfo: userInfo)
    }
}
