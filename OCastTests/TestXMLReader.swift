//
// TestOCastXMLReader.swift
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

/// Tests the XMLReader class.
class TestXMLReader: XCTestCase {
    
    override func setUp() {
    }

    override func tearDown() {
    }

    func testXMLValues() {
        let foo1Value = "Foo1"
        let foo2Value = "Foo2"
        let xmlString = "<foo1>\(foo1Value)<foo2>\(foo2Value)</foo2></foo1>"
        let xmlParser = XMLReader().parse(data: xmlString.data(using: .utf8)!)
        XCTAssertNotNil(xmlParser)
        XCTAssertEqual(foo1Value, xmlParser?["foo1"]?.value)
        XCTAssertEqual(foo2Value, xmlParser?["foo1"]?["foo2"]?.value)
    }
    
    func testXMLAttributes() {
        let foo1AttributeKey = "foo1attributeKey"
        let foo1Attribute = "foo1attribute"
        let foo2AttributeKey = "foo2attributeKey"
        let foo2Attribute = "foo2attribute"
        let xmlString = "<foo1 \(foo1AttributeKey)=\"\(foo1Attribute)\"><foo2 \(foo2AttributeKey)=\"\(foo2Attribute)\"></foo2></foo1>"
        let xmlParser = XMLReader().parse(data: xmlString.data(using: .utf8)!)
        XCTAssertNotNil(xmlParser)
        XCTAssertEqual(foo1Attribute, xmlParser?["foo1"]?.attributes?[foo1AttributeKey])
        XCTAssertEqual(foo2Attribute, xmlParser?["foo1"]?["foo2"]?.attributes?[foo2AttributeKey])
    }
    
    func testInvalidXML() {
        let xmlString = "<foo><foo>"
        let xmlParser = XMLReader().parse(data: xmlString.data(using: .utf8)!)
        XCTAssertNil(xmlParser)
    }
}
