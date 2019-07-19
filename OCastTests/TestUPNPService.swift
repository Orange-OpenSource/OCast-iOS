//
// TestUPNPService.swift
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

@testable import OCast
import XCTest

/// Tests the UPNP service class.
class TestUPNPService: XCTestCase {
    
    private let deviceID = "device-UUID"

    func testCorrectUSN() {
        let USN = "uuid:\(deviceID)"
        XCTAssertEqual(deviceID, UPNPService.extractUUID(from: USN))
    }
    
    func testRootDeviceUSN() {
        let USN = "uuid:\(deviceID)::upnp:rootdevice"
        XCTAssertEqual(deviceID, UPNPService.extractUUID(from: USN))
    }
    
    func testDeviceTypeUSN() {
        let USN = "uuid:\(deviceID)::urn:schemas-upnp-org:device:deviceType:ver"
        XCTAssertEqual(deviceID, UPNPService.extractUUID(from: USN))
    }
    
    func testServiceTypeUSN() {
        let USN = "uuid:\(deviceID)::urn:schemas-upnp- org:service:serviceType:ver"
        XCTAssertEqual(deviceID, UPNPService.extractUUID(from: USN))
    }
    
    func testBadUSN() {
        XCTAssertNil(UPNPService.extractUUID(from: deviceID))
    }
    
    func testCorrectDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success(let device):
                XCTAssertNotNil(device)
                XCTAssertEqual("4f8a97dd-c6ec-4469-9e27-0009743924a1", device.deviceID)
                XCTAssertEqual(URL(string: applicationURL), device.dialURL)
                XCTAssertEqual("Foo", device.friendlyName)
                XCTAssertEqual("FooFacturer", device.manufacturer)
                XCTAssertEqual("FooModel", device.modelName)
                expectation.fulfill()
            case .failure:
                XCTFail("Device provider should success")
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingFriendlyNameInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(removingTag: "friendlyName"),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingManufacturerInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(removingTag: "manufacturer"),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingModelNameInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(removingTag: "modelName"),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingUDNInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(removingTag: "UDN"),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingHeaderInDeviceDescription() {
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: [:])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeviceDescriptionWithoutData() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: nil,
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    expectation.fulfill()
                case .httpRequest:
                    XCTFail("Error should be bad content")
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeviceDescriptionWithError() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(),
                                                            error: URLError(.timedOut),
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    XCTFail("Error should be http request")
                case .httpRequest:
                    expectation.fulfill()
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBadStatusCodeInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(),
                                                            error: nil,
                                                            statusCode: 500,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "http://127.0.0.1/dd.xml"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    XCTFail("Error should be http request")
                case .httpRequest:
                    expectation.fulfill()
                }
            }
        }
        
        assertRequest(on: location, mockURLSession: mockURLSession)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBadLocationInDeviceDescription() {
        let applicationURL = "http://127.0.0.1/app"
        let mockURLSessionResponse = MockURLSessionResponse(data: loadResponse(),
                                                            error: nil,
                                                            statusCode: 200,
                                                            headers: ["Application-URL": applicationURL])
        let mockURLSession = MockURLSession(response: mockURLSessionResponse)
        let upnpService = UPNPService(urlSession: mockURLSession)
        let location = "😭"
        
        let expectation = self.expectation(description: "deviceDescription")
        upnpService.device(fromLocation: location) { result in
            switch result {
            case .success:
                XCTFail("Device provider should fail")
            case .failure(let error):
                switch error {
                case .badContent:
                    XCTFail("Error should be http request")
                case .httpRequest:
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNil(mockURLSession.mockURLSessionDataTask)
        wait(for: [expectation], timeout: 5.0)
    }
    
    private func loadResponse(removingTag tag: String? = nil) -> Data {
        var xmlResponse = """
        <root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:r="urn:restful-tv-org:schemas:upnp-dd">
        <specVersion>
            <major>1</major>
            <minor>0</minor>
        </specVersion>
        <URLBase>http://127.0.0.1:8080</URLBase>
        <device>
            <deviceType>urn:schemas-upnp-org:device:dail:1</deviceType>
            <friendlyName>Foo</friendlyName>
            <manufacturer>FooFacturer</manufacturer>
            <modelName>FooModel</modelName>
            <UDN>uuid:4f8a97dd-c6ec-4469-9e27-0009743924a1</UDN>
        </device>
        </root>
        """
        
        if let tag = tag {
            xmlResponse = xmlResponse.replacingOccurrences(of: "<\(tag)>[\\s\\S]*?<\\/\(tag)>", with: "", options: .regularExpression, range: nil)
        }
        
        return xmlResponse.data(using: .utf8)!
    }
    
    private func assertRequest(on url: String, mockURLSession: MockURLSession) {
        XCTAssertTrue(mockURLSession.mockURLSessionDataTask!.resumeCalled)
        //XCTAssertTrue(mockURLSession.finishTasksAndInvalidateCalled)
        XCTAssertEqual(mockURLSession.request?.url?.absoluteString, url)
        XCTAssertNotNil(mockURLSession.request?.allHTTPHeaderFields?["Date"])
    }
}
