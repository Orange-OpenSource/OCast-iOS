//
// ReferenceLinkTests.swift
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


class ReferenceLinkTests: XCTestCase , LinkDelegate {
    
    var testId = ""
    var linkDownCount = 0
    var browserLink:ReferenceLink?
    
    var isSuccessCallBack1 = false
    var isSuccessCallBack2 = false
    var isErrorCallBack1 = false
    var isErrorCallBack2 = false
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testLinkFactory() {
        
        var referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self,
                                                                                    profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.40", needsEvent: true, app2appURL: "", certInfo: nil))]
        XCTAssert(referenceLink.count == 1)
        
        if referenceLink[ReferenceDriver.LinkId.genericLink] == nil {
            XCTAssert(false)
        }
        
        browserLink = referenceLink[ReferenceDriver.LinkId.genericLink]
        
        guard let link = browserLink else {
            XCTAssert(false)
            return
        }
        
        XCTAssert (link.profile.ipAddress == "192.168.1.40")
        
        referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self,
                                                                                profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.42",  needsEvent: true, app2appURL: "", certInfo: nil))]
    }
    
    
    func testPingPong () {
        
        testId = "pingPong"
        
        let referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self,
                                                                                    profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.40", needsEvent: true, app2appURL: "", certInfo: nil))]
        
        if referenceLink[ReferenceDriver.LinkId.genericLink] == nil {
            XCTAssert(false)
        }
        
        browserLink = referenceLink[ReferenceDriver.LinkId.genericLink]
        
        guard let link = browserLink else {
            XCTAssert(false)
            return
        }
        
        linkDownCount = 0
        link.connect()
    }
    
    func testStatus () {
        
        let mockSocketProvider = SocketProvider(from: nil, certInfo: nil)
        var referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self,
                                                                                    profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.40", needsEvent: true, app2appURL: "", certInfo: nil))]

        browserLink = referenceLink[ReferenceDriver.LinkId.genericLink]

        browserLink?.connect()
          testId = "-1"
        var message = "{\"dst\":null,\"src\":null,\"type\":\"reply\",\"id\":-1,\"status\":\"internal_error\", \"message\": {}}"
        browserLink?.onMessageReceived(from: mockSocketProvider, message: message)
        
        testId = "replyOK"
        message = "{\"dst\":\"*\",\"src\":\"browser\",\"type\":\"reply\",\"id\":1,\"status\":\"OK\", \"message\":{\"service\":\"org.ocast.media\",\"data\":{\"name\":\"prepare\",\"params\":{\"code\":0}}}}"
        browserLink?.onMessageReceived(from: mockSocketProvider, message: message)
        
        testId = "replyNOK"
        message = "{\"dst\":\"*\",\"src\":\"browser\",\"type\":\"reply\",\"id\":2,\"status\":\"missing_mandatory_field\", \"message\":{}}"
        browserLink?.onMessageReceived(from: mockSocketProvider, message: message)
        
        testId = "eventOK"
        message = "{\"dst\":\"*\",\"src\":\"browser\",\"type\":\"event\",\"id\":1,\"message\":{\"service\":\"org.ocast.webapp\",\"data\":{\"name\":\"connectionStatus\",\"params\":{\"status\":\"connected\"}}}}"
        browserLink?.onMessageReceived(from: mockSocketProvider, message: message)
    }
    
    func testDisconnect () {
        
        var referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self,
                                                                                    profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.40", needsEvent: true, app2appURL: "", certInfo: nil))]
        
        browserLink = referenceLink[ReferenceDriver.LinkId.genericLink]

        testId = "disconnectKO"
        browserLink?.disconnect()
        XCTAssert(browserLink?.isDisconnecting == false)
        
        testId  = "disconnectOK"
        browserLink?.connect()
        browserLink?.disconnect()
        XCTAssert(browserLink?.isDisconnecting == true)
    }
    
       
    func onSuccessTestID(data: Command) {

        switch testId {

        case "replyOK", "eventOK":
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
    }
    
    func onErrorTestID (error: NSError?) {
        switch testId {
        case "-1", "replyNOK","payloadNOK" :
            XCTAssert(true)
        default:
            XCTAssert(false)
        }

    }
    
    func testSequenceID() {
        var referenceLink = [ReferenceDriver.LinkId.genericLink: ReferenceLink(from: self, profile: LinkProfile(identifier: ReferenceDriver.LinkId.genericLink.rawValue, ipAddress: "192.168.1.40", needsEvent: true, app2appURL: "", certInfo: nil))]
   
        browserLink = referenceLink[ReferenceDriver.LinkId.genericLink]
        
        XCTAssert (browserLink?.getSequenceId() == 1)
        
        browserLink?.sequenceID = Int.max
        XCTAssert(browserLink?.getSequenceId() == 1)
    }
        
    
    
    // MARK: - Link protocol
    func onEvent (payload: Event) {
        
        switch testId {
            case "eventOK":
            XCTAssert(true)
        default :
            XCTAssert (false)
        }
        
    }
    
    func onLinkConnected (from identifier: Int8) {
        
        guard let link = browserLink else {
            XCTAssert(false)
            return
        }
        
        switch testId {
        case "pingPong":
            // False until a link stub is implemented.
            XCTAssert(false)
            
        default:
            XCTAssert(link.commandSocket?.state == .connected)
        }
    }
    
    func onLinkDisconnected(from identifier: Int8) {
        guard let link = browserLink else {
            XCTAssert(false)
            return
        }
        
        switch testId {
        case "pingPong":
            
            XCTAssert(linkDownCount == 0)
            
            linkDownCount = 1
            
            XCTAssert(link.commandSocket?.state == .disconnected)
            
        case "disconnectOK":
            XCTAssert (true)
            
        default:
            XCTAssert(false)
        }
    }
    
    func onLinkFailure(from identifier: Int8) {
    }
    
}

