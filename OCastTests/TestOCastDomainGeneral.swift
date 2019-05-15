//
// TestOCastDomainGeneral.swift
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
import Foundation
@testable import OCast

class TestOCastDomainGeneral: XCTestCase {
    
    private let jsonData = Data("""
    {
        "status": "status",
        "id": 1,
        "message": {
            "service": "service",
            "data": {
                "name": "name",
                "options": {
                    "B": 2,
                    "C": 3,
                    "A": 1
                },
                "params": {
                    "type": "type",
                    "trackId": "trackId",
                    "enable": true
                }
            }
        },
        "type": "type",
        "src": "source",
        "dst": "destination"
    }
    """.utf8)
    
    private let wrongData = Data("""
    {
        "status": "status",
        "id": "STRING",
        "message": {
            "service": "service",
            "data": {
                "name": "name",
                "options": {
                    "B": 2,
                    "C": 3,
                    "A": 1
                },
                "params": {
                    "type": "type",
                    "trackId": "trackId",
                    "enable": true
                }
            }
        },
        "type": "type",
        "src": "source",
        "dst": "destination"
    }
    """.utf8)

    
    private let jsonRegexPattern = "\\{(\"status\":\"\\w+\",)?\"id\":\\d+,\"message\":\\{\"service\":\"\\w*\",\"data\":\\{(\"name\":\"\\w*\",)?(\"options\":\\{(\"\\w\":.+,?)+\\},)?\"params\":\\{(\"\\w*\":.*,?)*\\}\\}\\},\"type\":\"\\w*\",\"src\":\"\\w*\",\"dst\":\"\\w*\"\\}"
    
    private var jsonObject: OCastDeviceLayer<MediaTrackCommand>?
    
    override func setUp() {
        
        let mediaTrackCommand = MediaTrackCommand(type: "type", trackId: "trackId", enable: true)
        let oCastDataLayer = OCastDataLayer(name: "name", params: mediaTrackCommand, options: ["A":1 , "B":2, "C":3])
        let oCastApplicationLayer = OCastApplicationLayer(service: "service", data: oCastDataLayer)
        let oCastDeviceLayer = OCastDeviceLayer(source: "source", destination: "destination", id: 1, status: "status", type: "type", message: oCastApplicationLayer)

        jsonObject = oCastDeviceLayer
    }
    
    override func tearDown() {
    }
    
    func testDecodingWhenMissingId() throws {
        assertThrowsKeyNotFound("id", decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: try jsonData.json(deletingKeyPaths: "id"))
    }
    
    func testDecodingWhenMissingMessage() throws {
        assertThrowsKeyNotFound("message", decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: try jsonData.json(deletingKeyPaths: "message"))
    }
    
    func testDecodingWhenMissingType() throws {
        assertThrowsKeyNotFound("type", decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: try jsonData.json(deletingKeyPaths: "type"))
    }
    
    func testDecodingWhenMissingDestination() throws {
        assertThrowsKeyNotFound("dst", decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: try jsonData.json(deletingKeyPaths: "dst"))
    }
    
    func testDecodingWhenMissingSource() throws {
        assertThrowsKeyNotFound("src", decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: try jsonData.json(deletingKeyPaths: "src"))
    }
    
    func testEncodingMatchingPattern() throws {
        let jsonDataTest = try! JSONEncoder().encode(jsonObject)
        let jsonStringTest = String(data: jsonDataTest, encoding: .utf8)!
        let trimmedTest = jsonStringTest.replacingOccurrences(of: "\\s*", with: "", options: .regularExpression)
        
        XCTAssertNotNil(trimmedTest.range(of: jsonRegexPattern, options: .regularExpression, range: nil, locale: nil))
    }
    
    func testEncodingMismatchPattern() throws {
        let wrongObject = MediaTrackCommand(type: "type", trackId: "trackId", enable: true)
        let encodedData = try! JSONEncoder().encode(wrongObject)
        let encodedString = String(data: encodedData, encoding: .utf8)!
        let encoded = encodedString.replacingOccurrences(of: "\\s*", with: "", options: .regularExpression)

        XCTAssertNil(encoded.range(of: jsonRegexPattern, options: .regularExpression, range: nil, locale: nil))
    }

    func testDecodingValidType() {
        let decoded = try! JSONDecoder().decode(OCastDeviceLayer<MediaTrackCommand>.self, from: jsonData)
        XCTAssertTrue(isEqual(deviceLayerA: decoded, deviceLayerB: jsonObject!))
    }
    
    func testDecodingInvalidType() throws {
        assertThrowsWrongType(decoding: OCastDeviceLayer<MediaTrackCommand>.self, from: wrongData)
    }
    
    private func assertThrowsWrongType<T: Decodable>(decoding: T.Type, from data: Data, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try JSONDecoder().decode(decoding, from: data), file: file, line: line) { error in
            if case .typeMismatch(let type, _)? = error as? DecodingError {
                XCTAssert(true, error.localizedDescription, file: file, line: line)
            } else {
                XCTFail("Expected '.typeMismatch()' but got \(error)", file: file, line: line)
            }
        }
    }

    
    // Test that a missing key from the Json throwing an exception
    private func assertThrowsKeyNotFound<T: Decodable>(_ expectedKey: String, decoding: T.Type, from data: Data, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try JSONDecoder().decode(decoding, from: data), file: file, line: line) { error in
            if case .keyNotFound(let key, _)? = error as? DecodingError {
                XCTAssertEqual(expectedKey, key.stringValue, "Expected missing key '\(key.stringValue)' to equal '\(expectedKey)'.", file: file, line: line)
            } else {
                XCTFail("Expected '.keyNotFound(\(expectedKey))' but got \(error)", file: file, line: line)
            }
        }
    }
    
    private func isEqual(deviceLayerA: OCastDeviceLayer<MediaTrackCommand>, deviceLayerB: OCastDeviceLayer<MediaTrackCommand>) -> Bool {
        return {
            deviceLayerA.status == deviceLayerB.status
                && deviceLayerA.id == deviceLayerB.id
                && deviceLayerA.source == deviceLayerB.source
                && deviceLayerA.destination == deviceLayerB.destination
                && deviceLayerA.type == deviceLayerB.type
                && isEqual(applicationLayerA: deviceLayerA.message, applicationLayerB: deviceLayerB.message)
            }()
    }
    
    private func isEqual(applicationLayerA: OCastApplicationLayer<MediaTrackCommand>, applicationLayerB: OCastApplicationLayer<MediaTrackCommand>) -> Bool {
        return (
            applicationLayerA.service == applicationLayerB.service
                && isEqual(dataLayerA: applicationLayerA.data, dataLayerB: applicationLayerB.data)
        )
    }
    
    private func isEqual(dataLayerA: OCastDataLayer<MediaTrackCommand>, dataLayerB: OCastDataLayer<MediaTrackCommand>) -> Bool {
        // params aren't tested
        return {
            dataLayerA.name == dataLayerB.name
                && NSDictionary(dictionary: dataLayerA.options ?? [:]).isEqual(to: dataLayerB.options ?? [:])
            }()
    }

}

fileprivate extension Data {
    func json(deletingKeyPaths keyPaths: String...) throws -> Data {
        let decoded = try JSONSerialization.jsonObject(with: self, options: .mutableContainers) as AnyObject
        
        for keyPath in keyPaths {
            decoded.setValue(nil, forKeyPath: keyPath)
        }
        
        return try JSONSerialization.data(withJSONObject: decoded)
    }
}
