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


class ReferenceLinkTests: XCTestCase {
    
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
        browserLink = ReferenceLink(withDelegate: nil, andProfile: LinkProfile(module: .application, app2appURL: "192.168.1.40", certInfo: nil))
        XCTAssert (browserLink?.getSequenceId() == 1)
        browserLink?.sequenceID = Int.max
        XCTAssert(browserLink?.getSequenceId() == 1)
    }
    
    // MARK: - Link protocol
    func didReceive(event: Event) {
        switch testId {
        case "eventOK":
            XCTAssert(true)
        default :
            XCTAssert (false)
        }
    }
    
    func didConnect(linkWithIdentifier identifier: Int8) {
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
    
    func didDisconnect(linkWithIdentifier identifier: Int8) {
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

    func didFail(linkWithIdentifier identifier: Int8) {
        
    }
    
}

