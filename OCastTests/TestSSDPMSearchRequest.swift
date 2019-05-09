//
// TestSSDPMSearchRequest.swift
//
// Copyright 2019 Orange
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

/// Tests the SSDPMSearchRequest structure.
class TestSSDPMSearchRequest: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testMSearchRequest() {
        let host = "239.255.255.250:1900"
        let maxTime = 3
        let searchTarget = "urn:foo-org:service:foo:1"
        
        // Multiline adds the LF to obtain CRLF sequence
        let mSearchRequestString = """
        M-SEARCH * HTTP/1.1\r
        HOST: \(host)\r
        MAN: \"ssdp:discover\"\r
        MX: \(maxTime)\r
        ST: \(searchTarget)\r
        
        """
        
        let mSearchRequest = SSDPMSearchRequest(host: host, maxTime: maxTime, searchTarget: searchTarget)
        XCTAssertEqual(mSearchRequestString.data(using: .utf8), mSearchRequest.data!)
    }
}
