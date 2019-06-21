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
//  DeviceCenter.swift
//  OCast
//
//  Created by Christophe Azemar on 06/12/2018.
//

import Foundation

/// The notification sent each time new devices is discovered.
/// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the new devices.
public let DeviceCenterAddDevicesNotification = Notification.Name("DeviceCenterAddDevices")

/// The notification sent each time devices has been removed.
/// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the devices removed.
public let DeviceCenterRemoveDevicesNotification = Notification.Name("DeviceCenterRemoveDevices")

/// Notification sent each time an error has occured during discovery.
/// The userinfo `DeviceCenterErrorUserInfoKey` key contains an error if it occurs.
public let DeviceCenterDeviceDiscoveryErrorNotification = Notification.Name("DeviceCenterDeviceDiscoveryError")

/// The notification user info key representing the devices.
public let DeviceCenterDevicesUserInfoKey = "DeviceCenterDevicesUserInfoKey"

/// The notification user info key representing the error when the discovery is stopped.
public let DeviceCenterErrorUserInfoKey = "DeviceCenterErrorUserInfoKey"

/// Protocol for responding to device discovery events.
@objc public protocol DeviceCenterDelegate {
    
    /// Tells the delegate that new devices are found.
    ///
    /// - Parameters:
    ///   - center: The device center informing the delegate.
    ///   - devices: The new device found.
    func center(_ center: DeviceCenter, didAdd devices: [Device])
    
    /// Tells the delegate that devices are lost.
    ///
    /// - Parameters:
    ///   - center: The device center informing the delegate.
    ///   - devices: The device lost.
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
    
    /// The detected devices.
    private var detectedDevices: [String: Device] = [:]
    
    /// The delegate to receive discovery events.
    private var deviceDiscovery: DeviceDiscovery?
    
    /// The delegate to receive the device center events.
    public weak var delegate: DeviceCenterDelegate?
    
    /// The interval in seconds to refresh the devices. The minimum value is 5 seconds.
    public var deviceDiscoveryInterval: UInt16 {
        get { return deviceDiscovery?.interval ?? 0 }
        set { deviceDiscovery?.interval = newValue }
    }
    
    /// Registers a driver to discover devices of its manufacturer.
    ///
    /// - Parameters:
    ///   - deviceType: The Type of the driver class to register (for example ReferenceDevice.self)
    ///   - manufacturer: The device manufacturer used to identify it during the discovery.
    public func registerDevice(_ deviceType: Device.Type, forManufacturer manufacturer: String) {
        registeredDevices[manufacturer] = deviceType
        searchTargets.append(deviceType.searchTarget)
    }
    
    /// Resumes the discovery process to found devices on the local network.
    /// When a new devices are found the `DeviceCenterAddDevicesNotification` notification
    /// and the `center(_:didAdd:)` method are trigerred.
    /// When devices are lost the `DeviceCenterRemoveDevicesNotification` notification
    /// and the `center(_:didRemove:)` method are trigerred.
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
    
    /// Stops to discovery process. The devices are removed so the `DeviceCenterRemoveDevicesNotification`
    /// notification and the `center(_:didRemove:)` method will be triggered.
    /// This method will alse trigger the `DeviceCenterDeviceDiscoveryErrorNotification` notification
    /// and the `deviceDiscoveryDidStop(_:withError:)` method.
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
    func pauseDiscovery() -> Bool {
        return deviceDiscovery?.pause() ?? false
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAdd devices: [UPNPDevice]) {
        var newDevices = [Device]()
        devices.forEach { device in
            if let type = registeredDevices[device.manufacturer] {
                if detectedDevices[device.ipAddress] == nil {
                    let ocastDevice = type.init(upnpDevice: device)
                    detectedDevices[device.ipAddress] = ocastDevice
                    newDevices.append(ocastDevice)
                }
            }
        }
        delegate?.center(self, didAdd: newDevices)
        NotificationCenter.default.post(name: DeviceCenterAddDevicesNotification,
                                        object: self,
                                        userInfo: [DeviceCenterDevicesUserInfoKey: newDevices])
    }
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemove devices: [UPNPDevice]) {
        let ocastDevices = devices.compactMap({ return detectedDevices[$0.ipAddress] })
        delegate?.center(self, didRemove: ocastDevices)
        NotificationCenter.default.post(name: DeviceCenterRemoveDevicesNotification,
                                        object: self,
                                        userInfo: [DeviceCenterDevicesUserInfoKey: ocastDevices])
        ocastDevices.forEach { detectedDevices.removeValue(forKey: $0.ipAddress) }
    }
    
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, with error: Error?) {
        delegate?.centerDidStop(self, withError: error)
        
        var userInfo: [String: Any]?
        if let error = error {
            userInfo = [DeviceCenterErrorUserInfoKey: error]
        }
        NotificationCenter.default.post(name: DeviceCenterDeviceDiscoveryErrorNotification,
                                        object: self,
                                        userInfo: userInfo)
    }
}
