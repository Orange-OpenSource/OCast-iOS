//
// MediaControllerTests.swift
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

class MediaControllerTests: XCTestCase, MediaControllerProtocol {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetCode01 () {
        
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)
        

        let data: [String:Any] = ["service":"org.ocast.media","data":["name":"prepare","params":["code":0]]]
        
        guard let code = mediaController.getCode(from: data) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(code == MediaErrorCode.noError)
    }
    
    func testGetCode02 () {
        
        //Unknown code
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

        let data: [String:Any] = ["service":"org.ocast.media","data":["name":"prepare","params":["code":1]]]
        
        guard mediaController.getCode(from: data) != nil else {
            XCTAssert(true)
            return
        }
        
        XCTAssert(false)
    }
    
    func testGetCode03 () {
        
        
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

        
        // Code is missing
        
        var data: [String:Any] = ["service":"org.ocast.media","data":["name":"prepare","params":[]]]
        
        if mediaController.getCode(from: data) != nil  {
            XCTAssert(false)
        }
        
        data = ["service":"org.ocast.media","data":["name":"prepare","params":["options":"some options"]]]
        
        if mediaController.getCode(from: data) != nil  {
            XCTAssert(false)
        }
        data = ["service":"org.ocast.media","data":"the data"]
        
        if mediaController.getCode(from: data) != nil  {
            XCTAssert(false)
        }
        
        data = ["service":"org.ocast.media"]
        
        if mediaController.getCode(from: data) != nil  {
            XCTAssert(false)
        }
        
        
        if mediaController.getCode(from: nil) != nil  {
            XCTAssert(false)
        }
        
        XCTAssert(true)
    }
    
    func testGetMetadata01 () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

        
        let data : [String:Any] = ["service":"org.ocast.media","data":["name":"metadataChanged","params":["title":"Planète interdite","subtitle":"Brought to you by Orange OCast","logo":"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/","mediaType":"video","transferMode":"streamed","audioTracks":[["language":"fre","label":"#1 Fre","enabled":true,"id":"0"],["language":"eng","label":"#2 Eng","enabled":false,"id":"1"]],"videoTracks":[],"textTracks":[],"code":0],"options":[]]]
        
        guard let info =  mediaController.getMetaData(from: data) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(info.audioTracks?.count == 2)
    }
    
    func testGetMetadata02 () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

        
        if mediaController.getMetaData(from: nil) != nil {
            XCTAssert(false)
        }
        
        // "data" format is wrong
        var data : [String:Any] = ["service":"org.ocast.media","data":"the data"]
        
        if mediaController.getMetaData(from: data) != nil {
            XCTAssert(false)
        }
        
        // "params" is missing
        data = ["service":"org.ocast.media","data":["options": "some options"]]
        
        if mediaController.getMetaData(from: data) != nil {
            XCTAssert(false)
        }
        
        // mediaType is missing
        data = ["service":"org.ocast.media","data":["name":"metadataChanged","params":["title":"Planète interdite","subtitle":"Brought to you by Orange Cast","logo":"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/","transferMode":"streamed","audioTracks":[["language":"fre","label":"#1 Fre","enabled":true,"id":"0"],["language":"eng","label":"#2 Eng","enabled":false,"id":"1"]],"videoTracks":[],"textTracks":[],"code":0],"options":[]]]
        
        if mediaController.getMetaData(from: data) != nil {
            XCTAssert(false)
        }
        
        XCTAssert(true)
    }
    
    func testGetPlaybackInfo01 () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

    
        let data : [String:Any] = ["service":"org.ocast.media","data":["name":"playbackStatus","params":["state":"playing","volume":1,"mute":false,"position":1.486712077,"duration":5910.209,"code":0],"options":[]]]
        
        guard let info = mediaController.getPlaybackInfo(from: data) else  {
            XCTAssert(false)
            return
        }
        
        XCTAssert(info.duration == 5910.209)
        
    }
    
    func testGetPlaybackInfo02 () {
        let device = Device (baseURL:URL (string: "http://")!, ipAddress: "0.0.0.0.0", servicePort: 0, deviceID: "deviceID", friendlyName: "firendlyName", manufacturer: "Orange SA", modelName: "")
        let deviceMgr = DeviceManager (from: self, with: device, withCertificateInfo: nil)
        let applicationData = ApplicationDescription (app2appURL: "", version: "", rel: "", href: "", name: "")
        let appliMgr = ApplicationController (for: device, with: applicationData, andDriver: deviceMgr?.getDriver(for: device))
        
        let mediaController = appliMgr.getMediaController(for: self)

        
        if mediaController.getPlaybackInfo(from: nil) != nil {
            XCTAssert(false)
        }
        
        // Params is missing
        var data : [String:Any] = ["service":"org.ocast.media","data":["name":"playbackStatus"]]
        
        if mediaController.getPlaybackInfo(from: data) != nil {
            XCTAssert(false)
        }
        
        data = ["service":"org.ocast.media","data":"the data"]
        
        if mediaController.getPlaybackInfo(from: data) != nil {
            XCTAssert(false)
        }
    }
    
    
    // Unused protocol
    func onPlaybackStatus (data: PlaybackStatus) {}
    func onMetaDataChanged (data: MetaDataChanged) {}
}
