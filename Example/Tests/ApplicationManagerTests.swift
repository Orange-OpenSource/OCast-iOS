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
    
    func testMediaControllerCreation () {
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController(for: device, with: applicationData, target: "", driver:nil)
        
        XCTAssert(appliMgr.mediaController.serviceId == "org.ocast.media")
        
        // 1 Stream must be created at browser level
        XCTAssert(appliMgr.browser?.streams.count == 1)
        XCTAssert(appliMgr.browser?.streams["org.ocast.media"] != nil)
    }
    
    func mediaController(_ mediaController: MediaController, didReceivePlaybackStatus playbackStatus: PlaybackStatus) {}
    
    func mediaController(_ mediaController: MediaController, didReceiveMetadata metadata: Metadata) {}
}

