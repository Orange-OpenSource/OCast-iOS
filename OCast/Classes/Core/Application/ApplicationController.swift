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
public class ApplicationController: NSObject, DataStreamable, HttpProtocol, XMLHelperProtocol {

    // MARK: - Public interface

    init(for device: Device, with applicationData: ApplicationDescription, andDriver driver: DriverProtocol?) {
        self.device = device
        self.applicationData = applicationData
        self.driver = driver
        target = ""
    }

    /**
     Starts the web application on the device and opens a dedicated connection at driver level to communicate with the stick.
     Restart the web application if it is already running on the device.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */

    public func start(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        currentAction = .start
        successCallback = onSuccess
        errorCallback = onError
        target = "\(device.baseURL)/\(applicationData.name)"
        manageStream(for: self)

        if driver?.getState(for: .application) != .connected {
            driver?.connect(for: .application, with: applicationData, onSuccess: onConnectOK, onError: errorCallback)

        } else {
            initiateHttpRequest(from: self, with: .get, to: target, onSuccess: didReceiveHttpResponse(response:with:), onError: errorCallback)
        }
    }

    /**
     Joins the web application on the device. Fails if another web application is already running on the device.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */

    public func join(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        currentAction = Action.join
        target = "\(device.baseURL)"

        successCallback = onSuccess
        errorCallback = onError

        if driver?.getState(for: .application) != .connected {
            driver?.connect(for: .application, with: applicationData, onSuccess: onConnectOK, onError: errorCallback)
        } else {
            initiateHttpRequest(from: self, with: .get, to: target, onSuccess: didReceiveHttpResponse(response:with:), onError: onJoinError)
        }
    }

    /**
     Stops the web application on the device. Releases the dedicated web application connection at driver level.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */

    public func stop(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        currentAction = Action.stop
        target = "\(device.baseURL)/\(applicationData.name)"

        successCallback = onSuccess
        errorCallback = onError

        initiateHttpRequest(from: self, with: .get, to: target, onSuccess: didReceiveHttpResponse(response:with:), onError: errorCallback)
    }

    /**
     Used to get a reference to the mediaController
     - Returns: A pointer to the mediaController class
     */

    public func getMediaController(for sender: MediaControllerDelegate) -> MediaController {

        if mediaController == nil {
            mediaController = MediaController(with: sender)
            manageStream(for: mediaController!)
        }

        return mediaController!
    }

    /**
     Used to get control over a user's specific stream. 
     
     You need this when dealing with custom streams. See `DataStremable` for details on custom messaging.
      ```
        // Create a CustomStream class implementing the DataStremable protocol
        customStream = CustomStream() 
     
        // Register it so the application manager knows how to handle it.
        applicationController.manageStream(for: customStream)
      ```
        - Parameter stream: custom stream to be managed
     */

    public func manageStream(for stream: DataStreamable) {
        OCastLog.debug("ApplicationMgr: manage Stream for \(stream.serviceId)")
        startBrowser()
        stream.messageSender = DefaultMessagerSender(browser: browser!, serviceId: stream.serviceId)
        browser?.registerStream(for: stream)
    }

    // MARK: - DataStreamable Protocol

    static let applicationServiceId = "org.ocast.webapp"

    /// :nodoc:
    public let serviceId = ApplicationController.applicationServiceId

    /// :nodoc:
    public var messageSender: MessagerSender?

    /// :nodoc:
    public func onMessage(data: [String: Any]) {

        let name = data["name"] as? String ?? ""

        if name == "connectionStatus" {

            let params = data["params"] as? [String: String] ?? [:]

            if params["status"] == "connected" {
                OCastLog.debug("ApplicationMgr: Got the 'Connected' webapp message.")
                successCallback()
            }
        }
    }

    // MARK: - Internal

    var device: Device
    var driver: DriverProtocol?
    var target: String
    var successCallback: () -> Void = {}
    var errorCallback: (_ error: NSError?) -> Void = { _ in }
    var currentAction: Action = .start
    var applicationData: ApplicationDescription

    var browser: Browser?
    var mediaController: MediaController?

    enum Action: String {
        case start
        case join
        case stop
    }

    func reset() {
        browser = nil
        mediaController = nil
    }

    // MARK: - HTTP Request protocol and related methods

    func didReceiveHttpResponse(response _: HTTPURLResponse, with data: Data?) {

        guard let data = data else {
            OCastLog.error("ApplicationMgr: No content to parse.")
            return
        }

        let parserHelper = XMLHelper(fromSender: self, for: target)

        let key1 = XMLHelper.KeyDefinition(name: "state", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition(name: "name", isMandatory: true)

        parserHelper.parseDocument(data: data, withKeyList: [key1, key2])
    }

    // MARK: - XML Protocol

    func didParseWithError(for _: String, with error: Error, diagnostic: [String]) {
        OCastLog.error("ApplicationMgr: Parsing failed with error = \(error). Diagnostic: \(diagnostic)")
    }

    func didEndParsing(for _: String, result: [String: String], attributes _: [String: [String: String]]) {

        guard let state = result["state"] else {
            return
        }

        guard let name = result["name"] else {
            return
        }

        switch state {
        case "running":
            switch currentAction {

            case .start:
                initiateHttpRequest(from: self, with: .delete, to: "\(target)/run", onSuccess: onDeleteResponse(response:data:), onError: errorCallback)

            case .stop:
                initiateHttpRequest(from: self, with: .delete, to: target, onSuccess: onDeleteResponse(response:data:), onError: errorCallback)

            case .join:

                if applicationData.name == name {
                    successCallback()
                } else {
                    let newError = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Stick running another WebApp."])
                    errorCallback(newError)
                }
            }

        case "stopped":
            switch currentAction {

            case .start:
                initiateHttpRequest(from: self, with: .post, to: target, onSuccess: onPostResponse(response:data:), onError: errorCallback)

            case .stop:
                driver?.disconnect(for: .application, onSuccess: successCallback, onError: errorCallback)

            case .join:

                if applicationData.name == name {
                    start(onSuccess: successCallback, onError: errorCallback)
                } else {
                    let newError = NSError(domain: "ApplicationController", code: 0, userInfo: ["Error": "Stick running another WebApp."])
                    errorCallback(newError)
                }
            }

        default:
            return
        }
    }

    func onDeleteResponse(response _: HTTPURLResponse, data _: Data?) {
        OCastLog.debug("ApplicationMgr: Got a response to the Delete command.")
        initiateHttpRequest(from: self, with: .get, to: target, onSuccess: didReceiveHttpResponse(response:with:), onError: errorCallback)
    }

    func onPostResponse(response _: HTTPURLResponse, data _: Data?) {
        OCastLog.debug("ApplicationMgr: Got a response to the Post command. Waiting for the 'Connected' webapp message.")
    }

    func onJoinError(_ error: NSError?) {

        if error?.code == 404 {
            start(onSuccess: successCallback, onError: errorCallback)
        }
    }

    func onConnectOK() {
        initiateHttpRequest(from: self, with: .get, to: target, onSuccess: didReceiveHttpResponse(response:with:), onError: errorCallback)
    }

    func startBrowser() {

        if browser == nil {
            // FIXME: !!!
            browser = Browser(withDriver: driver as! BrowserDelegate)
        }
    }

    fileprivate final class DefaultMessagerSender: MessagerSender {

        let browser: Browser
        let serviceId: String

        init(browser: Browser, serviceId: String) {
            self.browser = browser
            self.serviceId = serviceId
        }

        func send(message: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {
            browser.sendData(data: message, for: serviceId, onSuccess: onSuccess, onError: onError)
        }
    }
}
