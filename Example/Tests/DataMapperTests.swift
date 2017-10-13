//
// DataMapperTests.swift
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

class DataMapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBrowser01 () {
        
        let msg: [String:Any] = ["service" : "org.ocast.webapp",
                                 "data"    : ["name"    :"connectionStatus",
                                              "params"  :["status":"connected"]]]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(browserData.data != nil)
        
        guard let service = browserData.service else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(service == "org.ocast.webapp")
        
    }
    
    func testBrowser02 () {
        
        // "service" is missing
        
        let msg: [String:Any] = [
            "data"    : ["name"    :"connectionStatus",
                         "params"  :["status":"connected"]]]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(browserData.data != nil)
        XCTAssert(browserData.service == nil)
    }
    
    func testBrowser03() {
        
        // "data" is missing
        let msg: [String:Any] = ["service" : "org.ocast.webapp"]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        XCTAssert(browserData.data == nil)
        XCTAssert(browserData.service != nil)
    }
    
    func testBrowser04() {
        
        // "service" and "data" are missing
        let msg: [String:Any] = [:]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        XCTAssert(browserData.data == nil)
        XCTAssert(browserData.service == nil)
    }
    
    func testBrowser05 () {
        
        // Service is not String based.
        
        let msg: [String:Any] = ["service" : 1,
                                 "data"    : ["name"    :"connectionStatus",
                                              "params"  :["status":"connected"]]]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(browserData.data != nil)
        
        XCTAssert(browserData.service == nil)
    }
    
    func testBrowser06 () {
        
        // Data is not a dictionnary.
        
        let msg: [String:Any] = ["service" : "org.ocast.webapp",
                                 "data"    : 5]
        
        guard let browserData = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(browserData.data == nil)
        
        XCTAssert(browserData.service != nil)
    }
    
    func testBrowser07 () {
        
        // Message is not a dictionnary.
        
        let msg = "a message"
        
        guard let _ = DataMapper().getBrowserData(with: DriverDataStructure(message: msg))  else {
            XCTAssert(true)
            return
        }
        
        XCTAssert(false)
    }

    func testPlayBackStatus01 () {
        
        let message = StreamStructure(name: "playbackStatus", params: ["state":"playing","volume":0.1,"mute":false,"position":0.99,"duration":596.4733333333334], options: nil)
        let data = DataMapper().getPlaybackStatus(with: message)
        XCTAssert(data.state == PlayerState.playing)
        XCTAssert(data.volume == 0.1)
        XCTAssert(data.mute == false)
        XCTAssert(data.position == 0.99)
        XCTAssert(data.duration == 596.4733333333334)
    }
    
    func testPlayBackStatus02() {
        // Missing parameter "state"
        
        let message = StreamStructure(name: "playbackStatus", params: ["volume":0.1,"position":0.99,"duration":596.4733333333334], options: nil)
        let data = DataMapper().getPlaybackStatus(with: message)
        XCTAssert(data.state == PlayerState.idle)
        XCTAssert(data.volume == 0.1)
        XCTAssert(data.mute == true)
        XCTAssert(data.position == 0.99)
        XCTAssert(data.duration == 596.4733333333334)
    }
    
    func testPlayBackStatus03() {
        // Wrong types
        
        let message = StreamStructure(name: "playbackStatus", params: ["state":true, "volume":true,"position":true,"duration":true,"mute": "OK"], options: nil)
        let data = DataMapper().getPlaybackStatus(with: message)
        XCTAssert(data.state == PlayerState.idle)
        XCTAssert(data.volume == 0)
        XCTAssert(data.mute == true)
        XCTAssert(data.position == 0)
        XCTAssert(data.duration == 0)
    }
    
    
    func testMetaData01 () {
        
        let message = StreamStructure(name: "MetaDataChanged", params: ["title":"my film","subtitle":"my subtitle", "logo":"http://www.here.com","mediaType":"audio"], options: nil)
        guard let data = DataMapper().getMetaData(from: message) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(data.title == "my film")
        XCTAssert(data.subtitle == "my subtitle")
        XCTAssert(data.logo == URL (string: "http://www.here.com"))
        XCTAssert(data.mediaType == MediaType.audio)
    }

    func testMetaData02 () {
        // Missing URL parameter
        let message = StreamStructure(name: "MetaDataChanged", params: ["title":"my film","subtitle":"my subtitle", "mediaType":"audio"], options: nil)
        
        guard let _ = DataMapper().getMetaData(from: message) else {
            XCTAssert(true)
            return
        }
        
        XCTAssert(false)
    }
    
    func testMetaData03 () {
        
        // Media type is not a String
        
        let message = StreamStructure(name: "MetaDataChanged", params: ["title":"my film","subtitle":"my subtitle", "logo":"http://www.here.com","mediaType":5], options: nil)
        guard let _ = DataMapper().getMetaData(from: message) else {
            XCTAssert(true)
            return
        }
        
    }
    
    func testMetaData04 () {
        // Title is not a String
        let message = StreamStructure(name: "MetaDataChanged", params: ["title": true,"subtitle":"my subtitle", "logo":"http://www.here.com","mediaType":"audio"], options: nil)
        
        guard let data = DataMapper().getMetaData(from: message) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(data.title == "")
    }
    
    
    func testMetaData05 () {
        
        let message = StreamStructure(name: "MetaDataChanged", params: ["title":"Planète interdite","subtitle":"Brought to you by Orange OCast","logo":"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/","mediaType":"video","transferMode":"streamed","audioTracks":[["language":"fre","label":"#1 Fre","enabled":true,"id":"0"],["language":"eng","label":"#2 Eng","enabled":false,"id":"1"]],"videoTracks":[],"textTracks":[],"code":0], options: nil)
        
        guard let data = DataMapper().getMetaData(from: message) else {
            XCTAssert(false)
            return
        }
        
        let audio = data.audioTracks
        let video = data.videoTracks
        let text = data.textTracks
        
        XCTAssert(audio?.count == 2)
        XCTAssert(video?.count == 0)
        XCTAssert(text?.count == 0)
        
    }

    func testMediaController () {
        var data: [String:Any] = ["name":"playbackStatus","params":["state":"buffering","volume":1,"mute":false,"position":1 ,"duration":10]]
        var result = DataMapper().getMediaControllerData(data: data)
        XCTAssert(result?.name == "playbackStatus")
        XCTAssert(result?.options == nil)
        XCTAssert(result?.params != nil)
        
        data = ["params":["state":"buffering","volume":1,"mute":false,"position":1 ,"duration":10]]
        result = DataMapper().getMediaControllerData(data: data)
        XCTAssert(result == nil)
        
        
        data = ["name":"playbackStatus"]
        result = DataMapper().getMediaControllerData(data: data)
        XCTAssert(result == nil)
        
    }

    func testGetTrack01 () {
        
        let tracks = [["language":"fre","label":"#1 Fre","enabled":true,"trackId":"0"],["language":"eng","label":"#2 Eng","enabled":false,"trackId":"1"]]
        
        guard let result = DataMapper().getTracks(with: tracks) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(result.count == 2)
        
        var track = result.first!
        XCTAssert(track.language  == "fre")
        XCTAssert(track.enabled  == true)
        XCTAssert(track.id  == "0")
        XCTAssert(track.label == "#1 Fre")
        
        track = result.last!
        XCTAssert(track.language  == "eng")
        XCTAssert(track.enabled  == false)
        XCTAssert(track.id  == "1")
        XCTAssert(track.label == "#2 Eng")
    }
    
    func testGetTrack02 () {
        
        // Wrong types
        let tracks = [["language":1,"label":2,"enabled":"true","id":1]]
        
        guard let result = DataMapper().getTracks(with: tracks) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(result.count == 1)
        
        let track = result.first!
        XCTAssert(track.language  == "")
        XCTAssert(track.enabled  == false)
        XCTAssert(track.id  == "")
        XCTAssert(track.label == "")

    }
    
    func testGetTrack03 () {
        
        // Wrong format
         let tracks = ["language":1,"label":2,"enabled":"true","id":1] as [String : Any]
        
        var result = DataMapper().getTracks(with: nil)
        
        if result == nil {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        result = DataMapper().getTracks(with: tracks)
        
        if result == nil {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }

    }
}
