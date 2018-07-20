//
//  OCastApplicationControllerTests.swift
//  OCastTests
//
//  Created by François Suc on 17/07/2018.
//  Copyright © 2018 Orange. All rights reserved.
//

import Foundation

//
// OCastDiscoveryTests.swift
//
// Copyright 2018 Orange
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
//

import OCast
import XCTest

/// Tests the OCast ApplicationController
class OCastApplicationControllerTests: OCastTestCase {
    
    /// The device manager to keep to manage the application controller
    var deviceManager: DeviceManager?
    
    override func setUp() {
        super.setUp()
        
        do {
            try mockServer.start()
        } catch {
            fatalError("Failed to start the OCast mock server")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        mockServer.stop()
    }
    
    /// Tests that an application controller can be retrieved for an existing app
    func testApplicationControllerSuccess() {
        let dialAppExpectation = self.expectation(description: "DialApp")
        let applicationControllerExpectation = self.expectation(description: "ApplicationController")
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            dialAppExpectation.fulfill()
            return .ok(name: name, state: .stopped)
        }
        
        let delegate = DiscoveryDelegate(addDevice: { device in
            DeviceManager(with: device)?.applicationController(for: "App1", onSuccess: { controller in
                XCTAssertEqual(controller.serviceId, "org.ocast.webapp")
                applicationControllerExpectation.fulfill()
            }, onError: { error in
                XCTFail("ApplicationController error: \(error?.debugDescription ?? "nil")")
            })
        }, removeDevice: { _ in
            XCTFail("No remove device should occur")
        })
        
        let discovery = DeviceDiscovery(forTargets: [OCastDiscoveryTests.defaultSearchTarget])
        discovery.delegate = delegate
        discovery.start()
        defer { discovery.stop() }
        
        wait(for: [dialAppExpectation, applicationControllerExpectation], timeout: 5, enforceOrder: true)
    }
    
    /// Test that an application controller cannot be optained for an unknown application
    func testApplicationControllerErrorUnknownApp() {
        let dialAppExpectation = self.expectation(description: "DialApp")
        let applicationControllerExpectation = self.expectation(description: "ApplicationController")
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            dialAppExpectation.fulfill()
            return .notFound
        }
        
        let delegate = DiscoveryDelegate(addDevice: { device in
            let deviceManager = DeviceManager(with: device)
            deviceManager?.applicationController(for: "App1", onSuccess: { _ in
                XCTFail("Application Controller shoud not succeed")
            }, onError: { error in
                applicationControllerExpectation.fulfill()
                XCTAssertNotNil(error)
            })
        }, removeDevice: { _ in
            XCTFail("No remove device should occur")
        })
        
        let discovery = DeviceDiscovery(forTargets: [OCastDiscoveryTests.defaultSearchTarget])
        discovery.delegate = delegate
        discovery.start()
        defer { discovery.stop() }
        
        wait(for: [dialAppExpectation, applicationControllerExpectation], timeout: 5, enforceOrder: true)
    }
    
    /// Tests that an application controller can start with running app
    func testApplicationControllerStartForRunningApp() {
        let webSocketConnectedExpectation = self.expectation(description: "WebSocketConnected")
        let applicationControllerStartedExpectation = self.expectation(description: "ApplicationControllerStarted")
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            return .ok(name: name, state: .running)
        }
        
        requests.wsConnect = { _ in
            webSocketConnectedExpectation.fulfill()
            return .ok
        }
        
        applicationControllerHelper(for: "App1") { controller in
            controller.start(onSuccess: {
                applicationControllerStartedExpectation.fulfill()
            }, onError: { error in
                XCTFail("ApplicationController start error: \(error?.debugDescription ?? "nil")")
            })
        }
        
        wait(for: [webSocketConnectedExpectation, applicationControllerStartedExpectation],
             timeout: 5,
             enforceOrder: true)
    }
    
    /// Tests that an application controller can start a stopped app
    func testApplicationControllerStartForStoppedApp() {
        let appStartingExpectation = self.expectation(description: "AppStarting")
        let appRunningExpectation = self.expectation(description: "AppRunning")
        let webSocketConnectedExpectation = self.expectation(description: "WebSocketConnected")
        let applicationControllerStartedExpectation = self.expectation(description: "ApplicationControllerStarted")
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            return .ok(name: name, state: .stopped)
        }
        
        requests.wsConnect = { send in
            
            // Once connected to WebSocket, allow SDK to start the App
            self.requests.appStart = { name in
                XCTAssertEqual(name, "App1")
                
                self.requests.appState = { name in
                    XCTAssertEqual(name, "App1")
                    appRunningExpectation.fulfill()
                    return .ok(name: name, state: .running)
                }
                
                // Wait 1s before sending connected event
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0, execute: {
                    send(OCastMockServer.webAppConnectedEventMessage)
                })
                
                appStartingExpectation.fulfill()
                return .ok
            }
            
            webSocketConnectedExpectation.fulfill()
            return .ok
        }
        
        applicationControllerHelper(for: "App1") { controller in
            controller.start(onSuccess: {
                applicationControllerStartedExpectation.fulfill()
            }, onError: { error in
                XCTFail("ApplicationController start error: \(error?.debugDescription ?? "nil")")
            })
        }
        
        wait(for: [webSocketConnectedExpectation, appStartingExpectation, appRunningExpectation, applicationControllerStartedExpectation],
             timeout: 5,
             enforceOrder: true)
    }
    
    /// Tests that an application controller cannot start when app fails to start
    func testApplicationControllerStartErrorWhenAppFailsToStart() {
        let webSocketConnectedExpectation = self.expectation(description: "WebSocketConnected")
        let appStartingExpectation = self.expectation(description: "AppStarting")
        let applicationControllerStartedExpectation = self.expectation(description: "ApplicationControllerStarted")
        let applicationControllerStartErrorExpectation = self.expectation(description: "ApplicationControllerStartError")
        applicationControllerStartedExpectation.isInverted = true
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            return .ok(name: name, state: .stopped)
        }
        
        requests.appStart = { _ in
            appStartingExpectation.fulfill()
            return .error
        }
        
        requests.wsConnect = { _ in
            webSocketConnectedExpectation.fulfill()
            return .ok
        }
        
        applicationControllerHelper(for: "App1") { controller in
            controller.start(onSuccess: {
                applicationControllerStartedExpectation.fulfill()
            }, onError: { _ in
                applicationControllerStartErrorExpectation.fulfill()
            })
        }
        
        wait(for: [webSocketConnectedExpectation, appStartingExpectation, applicationControllerStartErrorExpectation, applicationControllerStartedExpectation],
             timeout: 5,
             enforceOrder: true)
    }
    
    /// Tests that an application controller cannot start when app connected event is never emmited
    func testApplicationControllerStartTimoutsWhenAppConnectedIsNeverEmitted() {
        let webSocketConnectedExpectation = self.expectation(description: "WebSocketConnected")
        let appStartingExpectation = self.expectation(description: "AppStarting")
        let applicationControllerStartedExpectation = self.expectation(description: "ApplicationControllerStarted")
        let applicationControllerStartErrorExpectation = self.expectation(description: "ApplicationControllerStartError")
        applicationControllerStartedExpectation.isInverted = true
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            return .ok(name: name, state: .stopped)
        }
        
        requests.appStart = { _ in
            appStartingExpectation.fulfill()
            return .ok
        }
        
        requests.wsConnect = { _ in
            webSocketConnectedExpectation.fulfill()
            return .ok
        }
        
        applicationControllerHelper(for: "App1") { controller in
            controller.start(onSuccess: {
                applicationControllerStartedExpectation.fulfill()
            }, onError: { _ in
                applicationControllerStartErrorExpectation.fulfill()
            })
        }
        
        wait(for: [webSocketConnectedExpectation, appStartingExpectation], timeout: 5, enforceOrder: true)
        
        // Wait at least 60s as the SDK has an internal timer waiting for the appConnected event
        wait(for: [applicationControllerStartErrorExpectation, applicationControllerStartedExpectation], timeout: 65, enforceOrder: true)
    }
    
    /// Tests that an application controller can stop a running app
    func testApplicationControllerStopARunningApp() {
        let webSocketConnectedExpectation = self.expectation(description: "WebSocketConnected")
        let applicationControllerStopExpectation = self.expectation(description: "ApplicationControllerStop")
        let applicationControllerStoppedExpectation = self.expectation(description: "ApplicationControllerStopped")
        
        requests.appState = { name in
            XCTAssertEqual(name, "App1")
            return .ok(name: name, state: .stopped)
        }
        requests.wsConnect = { send in
            self.requests.appStart = { name in
                XCTAssertEqual(name, "App1")
                self.requests.appState = { name in
                    XCTAssertEqual(name, "App1")
                    return .ok(name: name, state: .running)
                }
                // Wait 1s before sending connected event
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0, execute: {
                    send(OCastMockServer.webAppConnectedEventMessage)
                })
                return .ok
            }
            webSocketConnectedExpectation.fulfill()
            return .ok
        }
        requests.appStop = { name in
            XCTAssertEqual(name, "App1")
            self.requests.appState = { name in
                XCTAssertEqual(name, "App1")
                return .ok(name: name, state: .stopped)
            }
            applicationControllerStopExpectation.fulfill()
            return .ok
        }
        
        applicationControllerHelper(for: "App1") { controller in
            controller.start(onSuccess: {
                controller.stop(onSuccess: {
                    applicationControllerStoppedExpectation.fulfill()
                }, onError: { error in
                    XCTFail("ApplicationController stop error: \(error?.debugDescription ?? "nil")")
                })
            }, onError: { error in
                XCTFail("ApplicationController start error: \(error?.debugDescription ?? "nil")")
            })
        }
        
        wait(for: [webSocketConnectedExpectation, applicationControllerStopExpectation, applicationControllerStoppedExpectation],
             timeout: 60,
             enforceOrder: true)
    }
    
    /// Helper that returns an ApplicationController for a given app, once device is discovered
    private func applicationControllerHelper(for app: String, _ on: @escaping (ApplicationController) -> Void) {
        //HACK1: DeviceDiscovery stops when device is detected
        //HACK2: Keep delegate referenced arround until not needed
        let discovery = DeviceDiscovery(forTargets: [OCastApplicationControllerTests.defaultSearchTarget])
        var delegate: DiscoveryDelegate? = DiscoveryDelegate()
        delegate!.addDevice = { device in
            self.deviceManager = DeviceManager(with: device)
            self.deviceManager?.applicationController(for: app, onSuccess: { controller in
                on(controller)
            }, onError: { error in
                XCTFail("ApplicationController error: \(error?.debugDescription ?? "nil")")
            })
            discovery.stop()
            delegate = nil
        }
        delegate!.removeDevice = { _ in
            discovery.stop()
            delegate = nil
            XCTFail("No remove device should occur")
        }
        discovery.delegate = delegate!
        discovery.start()
    }
}
