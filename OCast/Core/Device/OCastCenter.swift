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

public let OCastAddDeviceNotification = Notification.Name(kOCastAddDevice)
public let OCastRemoveDeviceNotification = Notification.Name(kOCastRemoveDevice)
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
    
    /// Gets called when a device is updated (name for example).
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - device: lost device information . See `Device` for details.
    func discovery(_ center: OCastCenter, didUpdateDevice device: OCastDeviceProtocol)
    
    /// Gets called when the discovery is stopped by error or not. All the devices are removed.
    ///
    /// - Parameters:
    ///   - center: center which call the method
    ///   - error: the error if there's a problem, nil if the `DeviceDiscovery` has been stopped normally.
    func discoveryDidStop(_ center: OCastCenter, withError error: Error?)
}

@objcMembers
public class OCastCenter: NSObject, DeviceDiscoveryDelegate {

    public weak var discoveryDelegate: OCastDiscoveryDelegate?
    
    private var registeredDevices: [String: OCastDeviceProtocol.Type] = [:]
    private var searchTargets: [String] = []
    // mac/device
    private var detectedDevice: [String: OCastDeviceProtocol] = [:]
    private var discovery: DeviceDiscovery?
    
    /// Registers a driver to connect to a device.
    ///
    /// - Parameters:
    ///   - deviceType: The Type of the driver class to register (for example OCastReferenceDevice.self)
    public func registerDevice(_ deviceType: OCastDeviceProtocol.Type) {
        registeredDevices[deviceType.manufacturer] = deviceType
        searchTargets.append(deviceType.searchTarget)
    }
    
    public func startDiscovery() {
        // stop old discovery if existing and running
        discovery?.stop()
        discovery = DeviceDiscovery(searchTargets)
        discovery?.delegate = self
        discovery?.resume()
    }
    
    public func stopDiscovery() {
        discovery?.delegate = nil
        discovery?.stop()
    }
    
    // MARK: DeviceDiscoveryDelegate
    public func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAdd devices: [Device]) {
        devices.forEach { device in
            if let type = registeredDevices[device.manufacturer] {
                if detectedDevice[device.ipAddress] == nil {
                    let ocastDevice = type.init(ipAddress: device.ipAddress, applicationURL: device.baseURL.absoluteString)
                    detectedDevice[device.ipAddress] = ocastDevice
                    discoveryDelegate?.discovery(self, didAddDevice: ocastDevice)
                    NotificationCenter.default.post(name: OCastAddDeviceNotification, object: ocastDevice)
                }
            }
        }
    }
    
    public func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemove devices: [Device]) {
        devices.forEach { device in
            if let device = detectedDevice[device.ipAddress] {
                detectedDevice.removeValue(forKey: device.ipAddress)
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

