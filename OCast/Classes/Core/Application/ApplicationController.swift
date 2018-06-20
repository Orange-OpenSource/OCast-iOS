//
// ApplicationController.swift
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

import Foundation

/**
 Provides means to control the web application.
 
 The ApplicationController gives you access to the `MediaController` object which provides your application with basic cast control functions.
 
 It also gives you access to custom messaging thru the `maangeStream()` function.

 A reference to the ApplicationController can be obtained using the `DeviceManager` class via the `getApplicationController()` function.

 ```
 deviceMgr.getApplicationController (
    for: applicationName,

    onSuccess: {applicationController in
        self.applicationController = applicationController
    },

    onError: {error in
        print ("-> ERROR for Application controller = \(String(describing: error))")
    }
 )

 ```
 */
@objcMembers
public class ApplicationController: NSObject, DataStream, HttpProtocol {

    var device: Device
    var driver: Driver?
    var target: String
    var currentState: State = .stopped
    var applicationData: ApplicationDescription
    
    var browser: Browser?
    
    enum State: String {
        case running
        case stopped
    }
    
    /// The MediaController to manage media
    public lazy var mediaController: MediaController = {
        let mediaController = MediaController()
        manage(stream: mediaController)
        
        return mediaController
    }()
    
    // XML Parser
    private let xmlParser = XMLHelper()
    
    // Timer
    private var semaphore: DispatchSemaphore?
    private var isConnectedEvent = false
    
    // MARK: - Public interface
    init(for device: Device, with applicationData: ApplicationDescription, target: String, driver: Driver?) {
        self.device = device
        self.applicationData = applicationData
        self.target = target
        self.driver = driver
        
        super.init()
        
        semaphore = DispatchSemaphore(value: 0)
    }

    /**
     Starts the web application on the device and opens a dedicated connection at driver level to communicate with the stick.
     Restart the web application if it is already running on the device.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func start(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        manage(stream: self)
        if driver?.state(for: .application) != .connected {
            driver?.connect(for: .application, with: applicationData,
                            onSuccess: {
                                self.applicationStatus(onSuccess: {
                                    if self.currentState == .running {
                                        onSuccess()
                                    } else {
                                        self.startApplication(onSuccess: onSuccess, onError: onError)
                                    }
                                }, onError: onError)
            }
                , onError: onError)
        } else {
            self.applicationStatus(onSuccess: {
                if self.currentState == .running {
                    onSuccess()
                } else {
                    self.startApplication(onSuccess: onSuccess, onError: onError)
                }
            }, onError: onError)
        }
    }

    /**
     Stops the web application on the device. Releases the dedicated web application connection at driver level.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func stop(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        applicationStatus(onSuccess: {
            if self.currentState == .running {
                self.stopApplication(onSuccess: {
                    self.driver?.disconnect(for: .application, onSuccess: onSuccess, onError: onError)
                }, onError: onError)
            } else {
                onSuccess()
            }
        }, onError: onError)
    }

    /**
     Used to get control over a user's specific stream. 
     
     You need this when dealing with custom streams. See `DataStream` for details on custom messaging.
      ```
        // Create a CustomStream class implementing the DataStream protocol
        customStream = CustomStream() 
     
        // Register it so the application manager knows how to handle it.
        applicationController.manageStream(for: customStream)
      ```
        - Parameter stream: custom stream to be managed
     */

    public func manage(stream: DataStream) {
        if browser == nil {
            browser = Browser()
            browser?.delegate = driver
        }
        if let browser = browser {
            stream.dataSender = DefaultDataSender(browser: browser, serviceId: stream.serviceId)
            browser.register(stream: stream)
        } else {
            OCastLog.error("Unable to manage stream (\(stream.serviceId) because browser is nil")
        }
    }

    // MARK: private methods
    private func startApplication(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        initiateHttpRequest(from: self, with: .post, to: target, onSuccess: { (response, _) in
            if response.statusCode == 201 {
                self.applicationStatus(onSuccess: {
                    self.isConnectedEvent = false
                    let _ = self.semaphore?.wait(timeout: .now() + 60)
                    if self.isConnectedEvent {
                        onSuccess()
                    } else {
                        let error = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "No message received from WS"])
                        onError(error)
                    }
                }, onError: { (error) in
                    onError(error)
                })
            } else {
                let error = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Application cannot be run."])
                onError(error)
            }
        }) { (error) in
            onError(error)
        }
    }
    
    private func stopApplication(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {        
        guard let runLink = URL(string: target)?.appendingPathComponent(applicationData.runLink ?? "run").absoluteString else {
            let error = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Bad run link"])
            onError(error)
            return
        }

        initiateHttpRequest(from: self, with: .delete, to: runLink, onSuccess: { (_, _) in
            self.applicationStatus(onSuccess: {
                if self.currentState == .stopped {
                    onSuccess()
                } else {
                    let error = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Application is not stopped."])
                    onError(error)
                }
            }, onError: { (error) in
                onError(error)
            })
        }) { (error) in
            onError(error)
        }
    }
    
    private func applicationStatus(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        initiateHttpRequest(from: self, with: .get, to: target, onSuccess: { (_, data) in
            guard let data = data else {
                OCastLog.error("ApplicationMgr: No content to parse.")
                let error = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "No content for status dial page"])
                onError(error)
                return
            }
            self.xmlParser.completionHandler = { (error, result, attributes) -> Void in
                if error == nil {
                    guard let state = result?["state"],
                        let _ = result?["name"],
                        let newState = State(rawValue: state) else {
                        let newError = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Missing parameters state/name"])
                        onError(newError)
                        return
                    }
                    self.currentState = newState
                    onSuccess()
                } else {
                    let newError = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Parsing error for \(self.target)\n Error: \(error?.localizedDescription ?? "")."])
                    onError(newError)
                }
            }
            self.xmlParser.parseDocument(data: data)
        }) { (error) in
            onError(error)
        }
    }
    
    // MARK: - DataStream methods
    static let applicationServiceId = "org.ocast.webapp"
    /// :nodoc:
    public let serviceId = ApplicationController.applicationServiceId
    /// :nodoc:
    public var dataSender: DataSender?
    /// :nodoc:
    public func onMessage(data: [String: Any]) {
        let name = data["name"] as? String
        if name == "connectedStatus" {
            let params = data["params"] as? [String: String]
            if params?["status"] == "connected" {
                isConnectedEvent = true
                semaphore?.signal()
            }
        }
    }
}
