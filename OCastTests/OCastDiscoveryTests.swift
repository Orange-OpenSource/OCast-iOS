//
// OCastDiscoveryTests.swift
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
import XCTest

/// Tests the OCast discovery
class OCastDiscoveryTests: OCastTestCase {
  
    override func setUp() {
        super.setUp()

        do {
            try mockServer.start()
        } catch {
            fatalError("Failed to start the OCast mock server")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        mockServer.stop()
    }
    
    /// Tests that a device is correctly detected
    func testDiscoveryAddDevice() {
        let dialSearchExpectation = self.expectation(description: "DialSearch")
        let dialLocationExpectation = self.expectation(description: "DialLocation")
        let addDeviceExpectation = self.expectation(description: "AddDevice")
        
        requests.search = { target in
            guard target == OCastDiscoveryTests.defaultSearchTarget else { return .ignore }
            dialSearchExpectation.fulfill()
            return .ok(uuid: OCastDiscoveryTests.defaultDeviceID)
        }
        requests.location = {
            dialLocationExpectation.fulfill()
            return OCastDiscoveryTests.defaultLocationResponse
        }
        requests.appState = { name in
            return .ok(name: name, state: .stopped)
        }
        
        let discovery = DeviceDiscovery(forTargets: [OCastDiscoveryTests.defaultSearchTarget])
        let delegate = DiscoveryDelegate(addDevice: { device in
            XCTAssertEqual(device.baseURL.absoluteString, self.mockServer.appsURL(forKey: "OCAST"))
            XCTAssertEqual(device.deviceID, OCastDiscoveryTests.defaultDeviceID)
            XCTAssertEqual(device.friendlyName, OCastDiscoveryTests.defaultFriendlyName)
            XCTAssertEqual(device.manufacturer, OCastDiscoveryTests.defaultManufacturer)
            XCTAssertEqual(device.modelName, OCastDiscoveryTests.defaultModelName)
            XCTAssertEqual(device.servicePort, OCastDiscoveryTests.defaultHTTPPort)
            addDeviceExpectation.fulfill()
        }, removeDevice: { _ in
            XCTFail("No remove device should occur")
        })
        discovery.delegate = delegate
        discovery.start()
        defer { discovery.stop() }
        
        wait(for: [dialSearchExpectation, dialLocationExpectation, addDeviceExpectation], timeout: 5, enforceOrder: true)
    }
    
    /// Tests that a discovered device that is lost is removed
    func testDiscoveryLostDeviceIsRemoved() {
        let addDeviceExpectation = self.expectation(description: "AddDevice")
        let removeDeviceExpectation = self.expectation(description: "RemoveDevice")
        
        let delegate = DiscoveryDelegate(addDevice: { device in
            addDeviceExpectation.fulfill()
        }, removeDevice: { device in
            XCTAssertEqual(device.deviceID, OCastDiscoveryTests.defaultDeviceID)
            removeDeviceExpectation.fulfill()
        })
        
        let discovery = DeviceDiscovery(forTargets: [OCastDiscoveryTests.defaultSearchTarget], withPolicy: .high)
        discovery.delegate = delegate
        discovery.start()
        defer { discovery.stop() }
        
        wait(for: [addDeviceExpectation], timeout: 5)

        // next M-SEARCH will not respond and should trigger timeout from DeviceDiscovery
        mockServer.stop()
        
        wait(for: [removeDeviceExpectation], timeout: 10)
    }
}
