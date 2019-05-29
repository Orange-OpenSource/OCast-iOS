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
//  OCastManager.swift
//  OCast
//
//  Created by Christophe Azemar on 06/12/2018.
//

import Foundation

public let kOCastAddDevice = "OCastAddDevice"
public let kOCastRemoveDevice = "OCastRemoveDevice"
public let kOCastDeviceDiscoveryError = "OCastDeviceDiscoveryError"

/// Notification sent each time a new device is discovered
public let OCastAddDeviceNotification = Notification.Name(kOCastAddDevice)
/// Notification sent each time a device has been removed
public let OCastRemoveDeviceNotification = Notification.Name(kOCastRemoveDevice)
/// Notification send each time a error has occured during discovery
public let OCastDeviceDiscoveryErrorNotification = Notification.Name(kOCastDeviceDiscoveryError)

/**
 Provides information on device searching activity.
 */

@objc public protocol OCastDiscoveryDelegate {
    
    /// Gets called when a new device is found.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - device: added device information . See `Device` for details.
    func discovery(_ center: OCastCenter, didAddDevice device: OCastDeviceProtocol)
    
    /// Gets called when a device is lost.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - device: lost device information . See `Device` for details.
    func discovery(_ center: OCastCenter, didRemoveDevice device: OCastDeviceProtocol)
    
    /// Gets called when the discovery is stopped by error or not. All the devices are removed.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - error: the error if there's a problem, nil if the `DeviceDiscovery` has been stopped normally.
    func discoveryDidStop(_ center: OCastCenter, withError error: Error?)
}

@objcMembers
/// Center which discover OCast devices on the network
public class OCastCenter: NSObject, DeviceDiscoveryDelegate {

    public weak var discoveryDelegate: OCastDiscoveryDelegate?
    
    // manufacturer/device's type
    private var registeredDevices: [String: OCastDeviceProtocol.Type] = [:]
    private var searchTargets: [String] = []
    // mac/device
    private var detectedDevices: [String: OCastDeviceProtocol] = [:]
    private var discovery: DeviceDiscovery?
    
    /// Registers a driver to connect to a device.
    ///
    /// - Parameters:
    ///   - deviceType: The Type of the driver class to register (for example OCastReferenceDevice.self)
    public func registerDevice(_ deviceType: OCastDeviceProtocol.Type) {
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
                    discoveryDelegate?.discovery(self, didAddDevice: ocastDevice)
                    NotificationCenter.default.post(name: OCastAddDeviceNotification, object: ocastDevice)
                }
            }
        }
    }
    
    public func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemove devices: [UPNPDevice]) {
        devices.forEach { device in
            if let device = detectedDevices[device.ipAddress] {
                detectedDevices.removeValue(forKey: device.ipAddress)
                discoveryDelegate?.discovery(self, didRemoveDevice: device)
                NotificationCenter.default.post(name: OCastRemoveDeviceNotification, object: device)
            }
        }
    }
    
    public func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, with error: Error?) {
        discoveryDelegate?.discoveryDidStop(self, withError: error)
        NotificationCenter.default.post(name: OCastDeviceDiscoveryErrorNotification, object: error)
    }
}

