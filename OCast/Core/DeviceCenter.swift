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

public let kDeviceCenterAddDevice = "DeviceCenterAddDevice"
public let kDeviceCenterRemoveDevice = "DeviceCenterRemoveDevice"
public let kDeviceCenterDeviceDiscoveryError = "DeviceCenterDeviceDiscoveryError"

/// Notification sent each time a new device is discovered
public let DeviceCenterAddDeviceNotification = Notification.Name(kDeviceCenterAddDevice)
/// Notification sent each time a device has been removed
public let DeviceCenterRemoveDeviceNotification = Notification.Name(kDeviceCenterRemoveDevice)
/// Notification send each time a error has occured during discovery
public let DeviceCenterDeviceDiscoveryErrorNotification = Notification.Name(kDeviceCenterDeviceDiscoveryError)

@objc public protocol DeviceCenterDelegate {
    
    /// Gets called when a new device is found.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - device: added device information . See `Device` for details.
    func center(_ center: DeviceCenter, didAddDevice device: DeviceProtocol)
    
    /// Gets called when a device is lost.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - device: lost device information . See `Device` for details.
    func center(_ center: DeviceCenter, didRemoveDevice device: DeviceProtocol)
    
    /// Gets called when the discovery is stopped by error or not. All the devices are removed.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - error: the error if there's a problem, nil if the `DeviceDiscovery` has been stopped normally.
    func centerDidStop(_ center: DeviceCenter, withError error: Error?)
}

@objcMembers
/// Center which discover OCast devices on the network
public class DeviceCenter: NSObject, DeviceDiscoveryDelegate {

    public weak var centerDelegate: DeviceCenterDelegate?
    
    // manufacturer/device's type
    private var registeredDevices: [String: DeviceProtocol.Type] = [:]
    private var searchTargets: [String] = []
    // mac/device
    private var detectedDevices: [String: DeviceProtocol] = [:]
    private var discovery: DeviceDiscovery?
    
    /// Registers a driver to discover it.
    ///
    /// - Parameters:
    ///   - deviceType: The Type of the driver class to register (for example OCastReferenceDevice.self)
    public func registerDevice(_ deviceType: DeviceProtocol.Type) {
        registeredDevices[deviceType.manufacturer] = deviceType
        searchTargets.append(deviceType.searchTarget)
    }
    
    /// Start to discover devices
    public func startDiscovery() {
        // stop old discovery if existing and running
        discovery?.stop()
        discovery = DeviceDiscovery(searchTargets)
        discovery?.delegate = self
        discovery?.resume()
    }
    
    // Stop to discover
    public func stopDiscovery() {
        discovery?.delegate = nil
        discovery?.stop()
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    public func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAdd devices: [UPNPDevice]) {
        devices.forEach { device in
            if let type = registeredDevices[device.manufacturer] {
                if detectedDevices[device.ipAddress] == nil {
                    let ocastDevice = type.init(upnpDevice: device)
                    detectedDevices[device.ipAddress] = ocastDevice
                    centerDelegate?.center(self, didAddDevice: ocastDevice)
                    NotificationCenter.default.post(name: DeviceCenterAddDeviceNotification, object: ocastDevice)
                }
            }
        }
    }
    
    public func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemove devices: [UPNPDevice]) {
        devices.forEach { device in
            if let device = detectedDevices[device.ipAddress] {
                detectedDevices.removeValue(forKey: device.ipAddress)
                centerDelegate?.center(self, didRemoveDevice: device)
                NotificationCenter.default.post(name: DeviceCenterRemoveDeviceNotification, object: device)
            }
        }
    }
    
    public func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, with error: Error?) {
        centerDelegate?.centerDidStop(self, withError: error)
        NotificationCenter.default.post(name: DeviceCenterDeviceDiscoveryErrorNotification, object: error)
    }
}

