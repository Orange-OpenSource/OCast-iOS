//
// ApplicationManagerTests.swift
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

internal final class DefaultDataStream: DataStream {

    let serviceId: String
    
    var browser: Browser?
    
    var dataSender: DataSender?
    
    init(forService serviceId: String) {
        self.serviceId = serviceId
    }
    
    func onMessage(data: [String : Any]) {
        // nothing
    }
}

class ApplicationManagerTests: XCTestCase, MediaControllerDelegate {

    var testID = 0
    
    func testMutliStream () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController(for: device, with: applicationData, andDriver: nil)
        
        let stream = DefaultDataStream (forService: "serviceExample")
        appliMgr.manage(stream: stream)
        
        let stream2 = DefaultDataStream (forService: "serviceExample-2")
        appliMgr.manage(stream: stream2)
        
        // Multiple streams can be created.
        XCTAssert(stream !== stream2)
        XCTAssert(stream.serviceId != stream2.serviceId)
    }
    
    func testMediaControllerCreation () {
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController(for: device, with: applicationData, andDriver: nil)
        
        let mediaController = appliMgr.mediaController(with: self)

        XCTAssert(mediaController.serviceId == "org.ocast.media")
        
        // 1 Stream must be created at browser level
        XCTAssert(appliMgr.browser?.streams.count == 1)
        XCTAssert(appliMgr.browser?.streams["org.ocast.media"] != nil)
    }
    
    func testMultiMediaController () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController(for: device, with: applicationData, andDriver: nil)
        
        let mediaController = appliMgr.mediaController(with: self)
        
        let mediaController2 = appliMgr.mediaController(with: self)
        
        // Only 1  mediacontroller instance can be created.
        XCTAssert(mediaController === mediaController2)
    }
    
    func testOnMessageConnectedOK () {
        testID = 1
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager(with: device)
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: nil)
        
        appliMgr.start(onSuccess: onSuccess, onError: onError(error:))
        
        let data : [String:Any] = ["name" : "connectionStatus", "params" : ["status":"connected"]]
        appliMgr.onMessage(data: data)
    }
    
    func testOnMessageConnectedKO () {
        testID = 2
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager(with: device)
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: nil)
        
        appliMgr.start(onSuccess: onSuccess, onError: onError(error:))
        
        let data : [String:Any] = ["name" : "connectionStatus", "params" : ["status":"internal error"]]
        appliMgr.onMessage(data: data)
    }
    
    func onSuccess () {
        if testID == 1 {
            XCTAssert(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func onError (error: NSError?) {
        XCTAssertTrue(false)
    }
    
    //MARK: - Unused protocols
    // MediaController protocol
    func onPlaybackStatus(data: PlaybackStatus) {}
    func onMetaDataChanged (data : Metadata) {}
}
