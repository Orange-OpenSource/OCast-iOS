//
// OCastTestCase.swift
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

/// Base class to factorize code
class OCastTestCase: XCTestCase {
    
    /// The default search target (diffrent from the read OCast service to prevent having real devices responding)
    static let defaultSearchTarget: String = {
        let uuid = UUID().uuidString
        return "urn:cast-ocast-org:service:cast:" + uuid.prefix(upTo: uuid.index(uuid.startIndex, offsetBy: 5))
    }()
    
    static let defaultHTTPPort: UInt16 = {
        do {
            let port = try OCastMockServer.findFreePort(startingFrom: 9000)
            print("Using default HTTP port: \(port)")
            return port
        } catch {
            fatalError("Could not find any free port")
        }
    }()
    
    /// The default manufacturer
    static let defaultManufacturer = "Orange SA"
    
    /// The default friendly name
    static let defaultFriendlyName = "OCAST_Key"
    
    /// The default model name
    static let defaultModelName = "Opencast"
    
    /// The default device identifier used by for the DIAL responses
    static let defaultDeviceID = "uuid:6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    
    /// The default DIAL location response
    static let defaultLocationResponse: OCastMockServer.LocationResponse = .ok(friendlyName: defaultFriendlyName, manufacturer: defaultManufacturer, modelName: defaultModelName, uuid: defaultDeviceID)
    
    /// The OCast mock server
    var mockServer: OCastMockServer!
    
    /// The requests handled by the OCast mock server, must be customized in each test
    var requests: OCastMockServer.Requests!
    
    override func setUp() {
        super.setUp()
        
        DeviceManager.registerDriver(ReferenceDriver.self, forManufacturer: OCastTestCase.defaultManufacturer)
        
        // Default behavior for the OCast mock server
        requests = OCastMockServer.Requests(search: { target in
            return target == OCastTestCase.defaultSearchTarget ? .ok(uuid: OCastTestCase.defaultDeviceID) : .ignore
        }, location: {
            return OCastTestCase.defaultLocationResponse
        }, appState: { _ in
            XCTFail("No app state request should occur")
            return .error
        }, appStart: { _ in
            XCTFail("No app start request should occur")
            return .error
        }, appStop: { _ in
            XCTFail("No app stop request should occur")
            return .error
        }, wsConnect: { _ in
            XCTFail("No web socket connection should occur")
            return .close
        }, wsMessage: { _, _ in
            XCTFail("No web socket request should occur")
            return .close
        })
        
        mockServer = OCastMockServer(httpPort: OCastTestCase.defaultHTTPPort, requests: ["OCAST": requests])
    }
}
