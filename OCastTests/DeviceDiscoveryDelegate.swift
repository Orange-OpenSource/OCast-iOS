//
// DeviceDiscoveryDelegate.swift
//
// Copyright 2018 Orange
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

import OCast

/// Converts a DeviceDiscoveryDelegate delegate to closure style
class DiscoveryDelegate: DeviceDiscoveryDelegate {
    
    // MARK: Public members
    
    /// The add device closure
    var addDevice: (_: Device) -> Void
    
    // The remove device closure
    var removeDevice: (_: Device) -> Void
    
    // MARK: Initializers
    
    init() {
        self.addDevice = { _ in }
        self.removeDevice = { _ in }
    }
    
    init(addDevice: @escaping (_: Device) -> Void, removeDevice: @escaping (_: Device) -> Void) {
        self.addDevice = addDevice
        self.removeDevice = removeDevice
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevice device: Device) {
        addDevice(device)
    }
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevice device: Device) {
        removeDevice(device)
    }
    
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, withError error: Error?) {
        
    }
}
