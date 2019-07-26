//
// TestReferenceDevice.swift
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

/// Tests the ReferenceDevice class.
class TestReferenceDevice: XCTestCase {
    
    private class TestCommandParams: OCastMessage {
        let test = "testValue"
    }
    
    private class TestReply: OCastMessage {
        let test: String
    }

    private var referenceDevice: ReferenceDevice!
    private var mockWebSocket: MockWebSocket!
    private var dialApplicationInfo: DIALApplicationInfo!
    private var mockDialService: MockDIALService!
    
    private let connectionEvent = """
    {"src":"browser","dst":"*","type":"event","id":1,"message":{"service":"org.ocast.webapp",
    "data":{"name":"connectedStatus","params":{"status":"connected"}}}}
    """
    
    // swiftlint:disable overridden_super_call
    override func setUp() {
        let upnpDevice = UPNPDevice(dialURL: URL(string: "http://127.0.0.1/apps")!,
                                    deviceID: "DeviceID",
                                    friendlyName: "Name",
                                    manufacturer: "Manufacturer",
                                    modelName: "Model")
        mockWebSocket = MockWebSocket(urlString: "ws://127.0.0.1", sslConfiguration: nil)
        dialApplicationInfo = DIALApplicationInfo(name: "MyApp",
                                                  state: .stopped,
                                                  webSocketURL: "http://127.0.0.1/apps/MyApp",
                                                  version: "1.0",
                                                  runLink: nil)
        mockDialService = MockDIALService(applicationInfo: dialApplicationInfo)
        referenceDevice = ReferenceDevice(upnpDevice: upnpDevice, webSocket: mockWebSocket, dialService: mockDialService, connectionEventTimeout: 5.0)
        referenceDevice.applicationName = "MyApp"
    }
    
    func testConnect() {
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            XCTAssertEqual(.connected, self.referenceDevice.state)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectBadSSLConfiguration() {
        mockWebSocket.connectionError = MockWebSocketError.invalidSSLError
        
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(SSLConfiguration()) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.webSocketConnectionFailed, ocastError)
            XCTAssertEqual(.disconnected, self.referenceDevice.state)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectAlreadyConnecting() {
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
        }
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateConnecting, ocastError)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectAlreadyConnected() {
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.referenceDevice.connect(nil) { error in
                XCTAssertNil(error)
                XCTAssertEqual(.connected, self.referenceDevice.state)
                connectExpectation.fulfill()
            }
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectDuringDisconnection() {
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.referenceDevice.disconnect { error in
                XCTAssertNil(error)
            }
            self.referenceDevice.connect(nil) { error in
                let ocastError = error as? OCastError
                XCTAssertNotNil(ocastError)
                XCTAssertEqual(OCastError.wrongStateDisconnecting, ocastError)
                connectExpectation.fulfill()
            }
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectWithoutApplicationName() {
        referenceDevice.applicationName = nil
        
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            XCTAssertEqual(.connected, self.referenceDevice.state)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectWithApplicationNotFound() {
        mockDialService.dialInfoError = .httpRequest(.badCode(404))
        
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.dialError, ocastError)
            XCTAssertEqual(.disconnected, self.referenceDevice.state)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testConnectWithBadDIALInfoResponse() {
        mockDialService.dialInfoError = .badContentResponse
        
        let connectExpectation = XCTestExpectation(description: "connectionExpectation")
        referenceDevice.connect(nil) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.dialError, ocastError)
            XCTAssertEqual(.disconnected, self.referenceDevice.state)
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 5.0)
    }
    
    func testDisconnect() {
        let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.referenceDevice.disconnect { error in
                XCTAssertNil(error)
                XCTAssertEqual(.disconnected, self.referenceDevice.state)
                disconnectionExpectation.fulfill()
            }
        }
        wait(for: [disconnectionExpectation], timeout: 5.0)
    }
    
    func testDisconnectDuringConnection() {
        referenceDevice.connect(nil) { _ in }
        let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")
        referenceDevice.disconnect { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateConnecting, ocastError)
            disconnectionExpectation.fulfill()
        }
        wait(for: [disconnectionExpectation], timeout: 5.0)
    }
    
    func testDisconnectAlreadyDisconnected() {
        let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")
        referenceDevice.disconnect { error in
            XCTAssertNil(error)
            XCTAssertEqual(.disconnected, self.referenceDevice.state)
            disconnectionExpectation.fulfill()
        }
        wait(for: [disconnectionExpectation], timeout: 5.0)
    }

    func testDisconnectAlreadyDisconnecting() {
        testConnect()
        referenceDevice.disconnect { error in
            XCTAssertNil(error)
        }
        let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")
        referenceDevice.disconnect { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateDisconnecting, ocastError)
            disconnectionExpectation.fulfill()
        }
        wait(for: [disconnectionExpectation], timeout: 5.0)
    }
    
    func testStartApplication() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
            self.referenceDevice.startApplication { error in
                XCTAssertNil(error)
                XCTAssertTrue(self.mockDialService.dialStartCalled)
                startAppExpectation.fulfill()
            }
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplicationAlreadyStarted() {
        let dialApplicationInfo = DIALApplicationInfo(name: "MyApp",
                                                      state: .running,
                                                      webSocketURL: "http://127.0.0.1/apps/MyApp",
                                                      version: "1.0",
                                                      runLink: nil)
        
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.mockDialService.dialApplicationInfo = dialApplicationInfo
            self.referenceDevice.startApplication { error in
                XCTAssertNil(error)
                XCTAssertFalse(self.mockDialService.dialStartCalled)
                startAppExpectation.fulfill()
            }
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplicationUpdatingApplicationName() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        let startAppExpectation2 = XCTestExpectation(description: "startAppExpectation2")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
            self.referenceDevice.startApplication { error in
                let ocastError = error as? OCastError
                XCTAssertNotNil(ocastError)
                XCTAssertEqual(OCastError.websocketConnectionEventNotReceived, ocastError)
                startAppExpectation.fulfill()
            }
            self.referenceDevice.applicationName = "MyApp2"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
                self.referenceDevice.startApplication { error in
                    XCTAssertNil(error)
                    startAppExpectation2.fulfill()
                }
            }
        }
        wait(for: [startAppExpectation, startAppExpectation2], timeout: 10.0)
    }
    
    func testStartApplicationWebSocketConnnectionEventNotReceived() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.referenceDevice.startApplication { error in
                let ocastError = error as? OCastError
                XCTAssertNotNil(ocastError)
                XCTAssertEqual(OCastError.websocketConnectionEventNotReceived, ocastError)
                startAppExpectation.fulfill()
            }
        }
        wait(for: [startAppExpectation], timeout: 10.0)
    }
    
    func testStartApplcationWithBadDIALInfoResponse() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.mockDialService.dialInfoError = .badContentResponse
            self.mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
            self.referenceDevice.startApplication { error in
                let ocastError = error as? OCastError
                XCTAssertNotNil(ocastError)
                XCTAssertEqual(OCastError.dialError, ocastError)
                startAppExpectation.fulfill()
            }
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplcationWithBadDIALStartResponse() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.connect(nil) { error in
            XCTAssertNil(error)
            self.mockDialService.dialStartError = .httpRequest(.badCode(404))
            self.mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
            self.referenceDevice.startApplication { error in
                let ocastError = error as? OCastError
                XCTAssertNotNil(ocastError)
                XCTAssertEqual(OCastError.dialError, ocastError)
                startAppExpectation.fulfill()
            }
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }

    func testStartApplicationWithoutApplicationName() {
        referenceDevice.applicationName = nil
        
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.startApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.applicationNameNotSet, ocastError)
            startAppExpectation.fulfill()
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplicationDisconnected() {
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.startApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateDisconnected, ocastError)
            startAppExpectation.fulfill()
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplicationDuringConnection() {
        referenceDevice.connect(nil) { _ in }
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.startApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateConnecting, ocastError)
            startAppExpectation.fulfill()
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStartApplicationDuringDisconnection() {
        testConnect()
        referenceDevice.disconnect { _ in }
        let startAppExpectation = XCTestExpectation(description: "startAppExpectation")
        referenceDevice.startApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateDisconnecting, ocastError)
            startAppExpectation.fulfill()
        }
        wait(for: [startAppExpectation], timeout: 5.0)
    }
    
    func testStopApplication() {
        testStartApplication()
        let stopAppExpectation = XCTestExpectation(description: "stopAppExpectation")
        referenceDevice.stopApplication { error in
            XCTAssertNil(error)
            stopAppExpectation.fulfill()
        }
        wait(for: [stopAppExpectation], timeout: 5.0)
    }
    
    func testStopApplicationWithoutApplicationName() {
        testStartApplication()
        referenceDevice.applicationName = nil
        let stopAppExpectation = XCTestExpectation(description: "stopAppExpectation")
        referenceDevice.stopApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.applicationNameNotSet, ocastError)
            stopAppExpectation.fulfill()
        }
        wait(for: [stopAppExpectation], timeout: 5.0)
    }
    
    func testStopApplcationWithBadDIALInfoResponse() {
        mockDialService.dialStopError = .badContentResponse
        let stopAppExpectation = XCTestExpectation(description: "stopAppExpectation")
        referenceDevice.stopApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.dialError, ocastError)
            stopAppExpectation.fulfill()
        }
        wait(for: [stopAppExpectation], timeout: 5.0)
    }
    
    func testStopApplcationWithBadDIALStopResponse() {
        mockDialService.dialStopError = .httpRequest(.badCode(500))
        let stopAppExpectation = XCTestExpectation(description: "stopAppExpectation")
        referenceDevice.stopApplication { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.dialError, ocastError)
            stopAppExpectation.fulfill()
        }
        wait(for: [stopAppExpectation], timeout: 5.0)
    }
    
    func testRegisterEvent() {
        let eventName = "MyEvent"
        let event = """
        {"src":"browser","dst":"*","type":"event","id":1,"message":{"service":"org.ocast.browser",
        "data":{"name":"\(eventName)","params":{"test":"testValue"}}}}
        """
        mockWebSocket.triggerIncomingMessage(event, after: 1.0)
        let registerEventExpectation = XCTestExpectation(description: "registerEventExpectation")
        referenceDevice.registerEvent(eventName) { jsonData in
            XCTAssertNotNil(jsonData)
            let jsonString = String(data: jsonData, encoding: .utf8)
            XCTAssertEqual(jsonString, event)
            registerEventExpectation.fulfill()
        }
        wait(for: [registerEventExpectation], timeout: 5.0)
    }
    
    func testSendMessageWithoutReplyResult() {
        testStartApplication()
        let name = "TestMessage"
        let serviceName = "org.ocast.testService"
        let data = OCastDataLayer(name: name, params: TestCommandParams(), options: nil)
        let message = OCastApplicationLayer(service: serviceName, data: data)
        let sendExpectation = XCTestExpectation(description: "sendExpectation")
        let reply = """
        {"src":"browser","dst":"*","type":"reply","status":"ok","id":1,"message":{"service":"\(serviceName)",
        "data":{"name":"\(name)","params":{"code":0}}}}
        """
        referenceDevice.send(message, on: .browser) { error in
            XCTAssertNil(error)
            sendExpectation.fulfill()
        }
        mockWebSocket.triggerIncomingMessage(reply, after: 1.0)
        wait(for: [sendExpectation], timeout: 10.0)
    }
    
    func testSendMessageWithReplyResult() {
        testStartApplication()
        let name = "TestMessage"
        let serviceName = "org.ocast.testService"
        let testValue = "TestValue"
        let data = OCastDataLayer(name: name, params: TestCommandParams(), options: nil)
        let message = OCastApplicationLayer(service: serviceName, data: data)
        let sendExpectation = XCTestExpectation(description: "sendExpectation")
        let reply = """
        {"src":"browser","dst":"*","type":"reply","status":"ok","id":1,"message":{"service":"\(serviceName)",
        "data":{"name":"\(name)","params":{"code":0,"test":"\(testValue)"}}}}
        """
        let completionBlock: ResultHandler<TestReply> = { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertEqual(testValue, result!.test)
            sendExpectation.fulfill()
        }
        referenceDevice.send(message, on: .browser, completion: completionBlock)
        mockWebSocket.triggerIncomingMessage(reply, after: 1.0)
        wait(for: [sendExpectation], timeout: 10.0)
    }
    
    func testSendMessageDisconnected() {
        let name = "TestMessage"
        let serviceName = "org.ocast.testService"
        let data = OCastDataLayer(name: name, params: TestCommandParams(), options: nil)
        let message = OCastApplicationLayer(service: serviceName, data: data)
        let sendExpectation = XCTestExpectation(description: "sendExpectation")
        referenceDevice.send(message, on: .browser) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.wrongStateDisconnected, ocastError)
            sendExpectation.fulfill()
        }
        wait(for: [sendExpectation], timeout: 10.0)
    }
    
    func testSendMessageApplicationNotStarted() {
        testConnect()
        let name = "TestMessage"
        let serviceName = "org.ocast.testService"
        let data = OCastDataLayer(name: name, params: TestCommandParams(), options: nil)
        let message = OCastApplicationLayer(service: serviceName, data: data)
        let sendExpectation = XCTestExpectation(description: "sendExpectation")
        let reply = """
        {"src":"browser","dst":"*","type":"reply","status":"ok","id":1,"message":{"service":"\(serviceName)",
        "data":{"name":"\(name)","params":{"code":0}}}}
        """
        mockWebSocket.triggerIncomingMessage(self.connectionEvent, after: 2.0)
        referenceDevice.send(message, on: .browser) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.mockDialService.dialStartCalled)
            sendExpectation.fulfill()
        }
        mockWebSocket.triggerIncomingMessage(reply, after: 3.0)
        wait(for: [sendExpectation], timeout: 10.0)
    }
    
    func testSendMessageError() {
        testStartApplication()
        let name = "TestMessage"
        let serviceName = "org.ocast.testService"
        let data = OCastDataLayer(name: name, params: TestCommandParams(), options: nil)
        let message = OCastApplicationLayer(service: serviceName, data: data)
        let sendExpectation = XCTestExpectation(description: "sendExpectation")
        mockWebSocket.sendError = .maximumPayloadReached
        referenceDevice.send(message, on: .browser) { error in
            let ocastError = error as? OCastError
            XCTAssertNotNil(ocastError)
            XCTAssertEqual(OCastError.unableToSendCommand, ocastError)
            sendExpectation.fulfill()
        }
        wait(for: [sendExpectation], timeout: 10.0)
    }
    
    func testDisconnection() {
        testConnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.mockWebSocket.disconnectionError = MockWebSocketError.timeoutError
            XCTAssertTrue(self.mockWebSocket.disconnect())
        }
        let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")
        let observer = NotificationCenter.default.addObserver(forName: .deviceDisconnectedEventNotification,
                                                              object: nil,
                                                              queue: nil) { _ in
                                                                XCTAssertEqual(.disconnected, self.referenceDevice.state)
                                                                disconnectionExpectation.fulfill()
        }
        wait(for: [disconnectionExpectation], timeout: 10.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
