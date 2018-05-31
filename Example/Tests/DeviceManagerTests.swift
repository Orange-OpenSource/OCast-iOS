//
// DeviceManagerTests.swift
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


import XCTest
@testable import OCast

class DeviceManagerTests: XCTestCase {
    
    func testDeviceManageCreation () {
        
        var device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "theDriver", modelName: "")
        var deviceMgr = DeviceManager (with: device, sslConfiguration: nil)
        
        // Must fail: The manufacturer does not macth any existing driver.
        XCTAssertNil(deviceMgr)
        
        device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        deviceMgr = DeviceManager(with: device)

        XCTAssertNotNil(deviceMgr)
    }
    
       
    func testApplicationController () {
        DeviceManager.registerDriver(ReferenceDriver.self, forManufacturer: "Orange SA")
        
        let device = Device(baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager(with: device)
        
        XCTAssertNotNil(deviceMgr)
    }
}
