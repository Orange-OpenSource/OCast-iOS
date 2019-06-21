//
// TestSSDPMSearchResponse.swift
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

/// Tests the SSDPMSearchResponse structure.
class TestSSDPMSearchResponse: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testCorrectMSearchResponse() {
        let ssdpHeaders: SSDPHeaders = [.location: "http://foo",
                                        .searchTarget: "urn:foo-org:service:foo:1",
                                        .server: "server",
                                        .usn: "urn:uuid:abcd-efgh-ijkl"]
        let mSearchResponse = SSDPMSearchResponse(from: ssdpHeaders)
        XCTAssertNotNil(mSearchResponse)
    }

    func testMSearchResponseWithoutLocation() {
        let ssdpHeaders: SSDPHeaders = [.searchTarget: "urn:foo-org:service:foo:1",
                                        .server: "server",
                                        .usn: "urn:uuid:abcd-efgh-ijkl"]
        let mSearchResponse = SSDPMSearchResponse(from: ssdpHeaders)
        XCTAssertNil(mSearchResponse)
    }
    
    func testMSearchResponseWithoutSearchTarget() {
        let ssdpHeaders: SSDPHeaders = [.location: "http://foo",
                                        .server: "server",
                                        .usn: "urn:uuid:abcd-efgh-ijkl"]
        let mSearchResponse = SSDPMSearchResponse(from: ssdpHeaders)
        XCTAssertNil(mSearchResponse)
    }
    
    func testMSearchResponseWithoutServer() {
        let ssdpHeaders: SSDPHeaders = [.location: "http://foo",
                                        .searchTarget: "urn:foo-org:service:foo:1",
                                        .usn: "urn:uuid:abcd-efgh-ijkl"]
        let mSearchResponse = SSDPMSearchResponse(from: ssdpHeaders)
        XCTAssertNil(mSearchResponse)
    }
    
    func testMSearchResponseWithoutUSN() {
        let ssdpHeaders: SSDPHeaders = [.location: "http://foo",
                                        .searchTarget: "urn:foo-org:service:foo:1",
                                        .server: "server"]
        let mSearchResponse = SSDPMSearchResponse(from: ssdpHeaders)
        XCTAssertNil(mSearchResponse)
    }
}