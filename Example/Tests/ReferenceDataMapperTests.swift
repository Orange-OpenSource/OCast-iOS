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

class ReferecnceDataMapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
       

    func testLinkEvent01 () {
        
         let message = "{\"dst\":\"*\",\"src\":\"browser\",\"type\":\"event\",\"id\":2,\"message\":{\"service\":\"org.ocast.webapp\",\"data\":{\"name\":\"connectionStatus\",\"params\":{\"status\":\"connected\"}}}}"
        
        guard let referenceLink = ReferenceDataMapper().referenceTransformForLink(for: message) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(referenceLink.status == nil)
        XCTAssert(referenceLink.destination == "*")
        XCTAssert(referenceLink.source == "browser")
        XCTAssert(referenceLink.type == "event")
        XCTAssert(referenceLink.identifier == 2)
        XCTAssert(referenceLink.message != nil)
        
    }
    
    func testLinkEvent02 () {
        
        // Mandatory "dst" parameter is missing
        var message = "{\"src\":\"browser\",\"type\":\"event\",\"id\":2,\"message\":{\"service\":\"org.ocast.webapp\",\"data\":{\"name\":\"connectionStatus\",\"params\":{\"status\":\"connected\"}}}}"
        
        guard let referenceLink = ReferenceDataMapper().referenceTransformForLink(for: message) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(referenceLink.destination == "")
        
        // Mandatory "dst" parameter is not String based
        
        message = "{\"dst\": 2,\"src\":\"browser\",\"type\":\"event\",\"id\":2,\"message\":{\"service\":\"org.ocast.webapp\",\"data\":{\"name\":\"connectionStatus\",\"params\":{\"status\":\"connected\"}}}}"
        XCTAssert(referenceLink.destination == "")
        
    }
    
  
}
