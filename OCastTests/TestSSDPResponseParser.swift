//
// TestSSDPResponseParser.swift
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

/// Tests the SSDPResponseParser class.
class TestSSDPResponseParser: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testCorrectSSDPResponse() {
        let location = "http://127.0.0.1/dd.xml"
        let searchTarget = "urn:foo-org:service:foo:1"
        let server = "Foo/1.0 UPnP/2.0 CléTV/2.0"
        let USN = "uuid:abcd-efgh-ijkl"
        // Multiline adds the LF to obtain CRLF sequence
        let mSearchResponseString = """
        HTTP/1.1 200 OK\r
        CACHE-CONTROL: max-age = 0\r
        EXT:\r
        LOCATION: \(location)\r
        SERVER: \(server)\r
        ST: \(searchTarget)\r
        USN: \(USN)\r
        BOOTID.UPNP.ORG: 1\r
        
        """
        
        let mSearchResponse = SSDPResponseParser().parse(response: mSearchResponseString)
        XCTAssertNotNil(mSearchResponse)
        XCTAssertEqual(location, mSearchResponse!.location)
        XCTAssertEqual(searchTarget, mSearchResponse!.searchTarget)
        XCTAssertEqual(server, mSearchResponse!.server)
        XCTAssertEqual(USN, mSearchResponse!.USN)
    }
    
    func testLowercasedHeaderKeysSSDPResponse() {
        let location = "http://127.0.0.1/dd.xml"
        let searchTarget = "urn:foo-org:service:foo:1"
        let server = "Foo/1.0 UPnP/2.0 CléTV/2.0"
        let USN = "uuid:abcd-efgh-ijkl"
        // Multiline adds the LF to obtain CRLF sequence
        let mSearchResponseString = """
        HTTP/1.1 200 OK\r
        cache-control: max-age = 0\r
        ext:\r
        location: \(location)\r
        server: \(server)\r
        st: \(searchTarget)\r
        usn: \(USN)\r
        bootid.upnp.org: 1\r
        
        """
        
        let mSearchResponse = SSDPResponseParser().parse(response: mSearchResponseString)
        XCTAssertNotNil(mSearchResponse)
        XCTAssertEqual(location, mSearchResponse!.location)
        XCTAssertEqual(searchTarget, mSearchResponse!.searchTarget)
        XCTAssertEqual(server, mSearchResponse!.server)
        XCTAssertEqual(USN, mSearchResponse!.USN)
    }
    
    func testBadRequestLineSSDPResponse() {
        // Multiline adds the LF to obtain CRLF sequence
        let mSearchResponseString = """
        http/1.1 200 ok\r
        CACHE-CONTROL: max-age = 0\r
        EXT:\r
        LOCATION: http://foo\r
        SERVER: Foo/1.0 UPnP/2.0 CléTV/2.0\r
        ST: urn:foo-org:service:foo:1\r
        USN: uuid:abcd-efgh-ijkl\r
        BOOTID.UPNP.ORG: 1\r
        
        """
        
        let mSearchResponse = SSDPResponseParser().parse(response: mSearchResponseString)
        XCTAssertNil(mSearchResponse)
    }
    
    func testMissingMandatoryHeaderSSDPResponse() {
        // Multiline adds the LF to obtain CRLF sequence
        let mSearchResponseString = """
        HTTP/1.1 200 OK\r
        CACHE-CONTROL: max-age = 0\r
        EXT:\r
        SERVER: Foo/1.0 UPnP/2.0 CléTV/2.0\r
        ST: urn:foo-org:service:foo:1\r
        USN: uuid:abcd-efgh-ijkl\r
        BOOTID.UPNP.ORG: 1\r
        
        """
        
        let mSearchResponse = SSDPResponseParser().parse(response: mSearchResponseString)
        XCTAssertNil(mSearchResponse)
    }

}
