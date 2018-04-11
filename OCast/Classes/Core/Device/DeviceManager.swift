//
// DeviceManager.swift
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

@objc public protocol DeviceManagerDelegate {
    func onFailure(error: NSError)
}

/**
 Device manager is used to get control over your device.
 ```
 deviceManager = DeviceManager (from: self, with: device, withCertificateInfo: nil)
 ```

 */
@objcMembers
@objc public final class DeviceManager: NSObject, DriverDelegate, HttpProtocol, XMLHelperDelegate {
    
    // MARK: - Internal
    public weak var delegate:DeviceManagerDelegate?
    // app info
    var currentTarget: String!
    var currentApplicationData: ApplicationDescription!
    var currentApplicationName: String!
    // application controllers
    var applicationControllers: [ApplicationController] = []
    // callback
    var successCallback: () -> Void = {  }
    var errorCallback: (_ error: NSError?) -> Void = { _ in }
    // settings
    var publicSettings: DriverPublicSettings?
    var privateSettings: DriverPrivateSettings?
    // ssl
    var certificateInfo: CertificateInfo?
    // timer
    var reconnectionRetry: Int8 = 0
    let maxReconnectionRetry: Int8 = 5
    var failureTimer = Timer()
    // drivers
    static var driverFactories: [String: DriverFactory] = [:]
    var driver: Driver?
    var device: Device

    // MARK: - Public interface

    /**
     Initializes a new DeviceManager.

     - Parameters:
         - sender: module that will receive further notifications
         - device: the device to be managed
         - certificateInfo: Optional. An array of certificates to establish secured connections to the device.
     */

    public init?(with device: Device, withCertificateInfo certificateInfo: CertificateInfo? = nil) {
        if DeviceManager.driverFactories[device.manufacturer] == nil {
            OCastLog.error("DeviceManager: Driver for device is not registered")
            return nil
        }
        self.device = device
        self.certificateInfo = certificateInfo
        super.init()
        driver = driver(for: device)

    }

    /**
     Not implemented in this version.
     
     
     Used to get a reference to the publicSettingController class
     - Parameters:
         - onSuccess: the closure to be called in case of success. Returns a reference to the publicSettingController.
         - onError: the closure to be called in case of error
     */
    public func publicSettingsController(onSuccess: @escaping (_: DriverPublicSettings) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        guard let driver = driver else {
            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Driver is not created."])
            onError(newError)
            return
        }

        if driver.state(for: .publicSettings) == .connected, let driver = driver as? DriverPublicSettings {
            onSuccess(driver)
            return
        }

        driver.register(self, forModule: .publicSettings)

        currentApplicationData = ApplicationDescription(app2appURL: "", version: "", rel: "", href: "", name: "")

        driver.connect(for: .publicSettings, with: currentApplicationData,
                       onSuccess: {
                            self.publicSettings = driver as? DriverPublicSettings
                            if let publicSettingsCtrl = self.publicSettings {
                                onSuccess(publicSettingsCtrl)
                            }
                       },

                       onError: { onError($0) }
        )
    }

    /**
     Not implemented in this version.
     
     
     Used to release the reference to the publicSettingController class.
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func releasePublicSettingsController(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        driver?.disconnect(for: .publicSettings, onSuccess: onSuccess, onError: onError)
    }

    /**
     Not implemented in this version.
     
     
     Used to get a reference to the privateSettingController class
     - Parameters:
         - onSuccess: the closure to be called in case of success; Returns a reference to the privateSettingController.
         - onError: the closure to be called in case of error
     */
    public func privateSettingsController(onSuccess: @escaping (_: DriverPrivateSettings) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        guard let driver = driver else {
            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Driver is not created."])
            onError(newError)
            return
        }

        if !driver.privateSettingsAllowed() {
            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Private settings are not available"])
            errorCallback(newError)
            return
        }

        driver.register(self, forModule: .privateSettings)

        if driver.state(for: .privateSettings) == .connected, let driver = driver as? DriverPrivateSettings {
            onSuccess(driver)
            return
        }

        currentApplicationData = ApplicationDescription(app2appURL: "", version: "", rel: "", href: "", name: "")

        driver.connect(for: .privateSettings, with: currentApplicationData,
                       onSuccess: {
                           self.privateSettings = driver as? DriverPrivateSettings
                            if let privateSettingsCtrl = self.privateSettings {
                                onSuccess(privateSettingsCtrl)
                            }
                       },

                       onError: { onError($0) }
        )
    }

    /**
     Not implemented in this version.
     
     
     Used to release the reference to the privateSettingController class.
     - Parameters:
         - onSuccess: the closure to be called in case of success
         - onError: the closure to be called in case of error
     */
    public func releasePrivateSettingsController(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        driver?.disconnect(for: .privateSettings, onSuccess: onSuccess, onError: onError)
    }

    /**
     Used to get a reference to the applicationController class
     - Parameters:
         - onSuccess: the closure to be called in case of success. Returns a reference to the applicationController.
         - onError: the closure to be called in case of error
     */
    public func applicationController(for applicationName: String, onSuccess: @escaping (_: ApplicationController) -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        
        let controller = applicationControllers.first(where: { (appController) -> Bool in
            return appController.applicationData.name == applicationName
        })
        if let controller = controller {
            onSuccess(controller)
            return
        }
        
        currentApplicationName = applicationName
        currentTarget = "\(device.baseURL)/\(applicationName)"
        
        applicationData(
            onSuccess: {
                let newController = ApplicationController(for: self.device, with: self.currentApplicationData, andDriver: self.driver)
                self.driver?.register(self, forModule: .application)
                self.applicationControllers.append(newController)
                onSuccess(newController)
        },
            onError: { onError($0) }
        )
    }

    /**
     Registers a driver to connect to a device.

     - Parameters:
        - name: Driver manufacturer's name. Caps sensitive. This value must match the manufacturer name present in the response to a MSEARCH Target.
        - factory: The factory instance that is in chrage of buildng a driver instance.
     */
   public static func registerDriver(forName name: String, factory: DriverFactory) -> Bool {
        driverFactories[name] = factory
        return true
    }
    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Private methods
    func driver(for device: Device) -> Driver? {
        if let factory = DeviceManager.driverFactories[device.manufacturer] {
            return factory.make(for: device.ipAddress, with: certificateInfo)
        } else {
            OCastLog.error("DeviceManager: Could not initialize the \(device.manufacturer) driver.")
            return nil
        }
    }

    func resetAllContexts() {
        applicationControllers.forEach { $0.reset() }
        applicationControllers.removeAll()
        publicSettings = nil
        privateSettings = nil
    }

    func applicationData(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        successCallback = onSuccess
        errorCallback = onError

        initiateHttpRequest(from: self, with: .get, to: currentTarget, onSuccess: didReceiveHttpResponse(response:with:), onError: onError)
    }

    // MARK: - HTTP Request protocol and related methods
    func didReceiveHttpResponse(response _: HTTPURLResponse, with data: Data?) {

        guard let data = data else {
            OCastLog.error("ApplicationMgr: No content to parse.")
            return
        }

        let parserHelper = XMLHelper(for: currentTarget)
        parserHelper.delegate = self

        let key1 = XMLHelper.KeyDefinition(name: "ocast:X_OCAST_App2AppURL", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition(name: "ocast:X_OCAST_Version", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition(name: "link", isMandatory: true)

        parserHelper.parseDocument(data: data, withKeyList: [key1, key2, key3])
    }

    // MARK: - XML Protocol
    func didParseWithError(for _: String, with error: Error, diagnostic: [String]) {
        OCastLog.error("DeviceMgr: Parsing failed with error = \(error). Diagnostic: \(diagnostic)")

        currentApplicationData = ApplicationDescription(app2appURL: "", version: "", rel: "", href: "", name: currentApplicationName ?? "")
        successCallback()
    }

    func didEndParsing(for _: String, result: [String: String], attributes: [String: [String: String]]) {

        let app2URL = result["ocast:X_OCAST_App2AppURL"]!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let version = result["ocast:X_OCAST_Version"]!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let linkAttributes = attributes["link"]!
        let rel = linkAttributes["rel"] ?? "run"
        let href = linkAttributes["href"] ?? ""
        
       let newURL = app2URL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        currentApplicationData = ApplicationDescription(app2appURL: newURL, version: version, rel: rel, href: href, name: currentApplicationName)
        successCallback()
    }

    // MARK: DriverDelegate methods
    public func onFailure(error: NSError?) {
        OCastLog.debug("DeviceMgr: Received a Driver failure indication (\(error.debugDescription)).")
        reconnectAllSessions()
    }


   // MARK: Miscellaneous
    
    @objc func onFailureTimerExpiry(timer _: Timer) {
        OCastLog.debug("DeviceMgr: onFailureTimerExpiry")

        if reconnectionRetry == maxReconnectionRetry {
            OCastLog.debug("DeviceMgr: Max reconnection retry is reached. Stopping retry process.")

            resetFailureTimer()
            resetAllContexts()

            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Driver is disconnected."])
            delegate?.onFailure(error: newError)

            return
        }

        failureTimer.invalidate()
        reconnectAllSessions()
    }

    func resetFailureTimer() {
        OCastLog.debug("DeviceMgr: Resetting failure timer.")

        failureTimer.invalidate()
        reconnectionRetry = 0
    }

    func reconnectAllSessions() {
        if !failureTimer.isValid {

            OCastLog.debug("DeviceMgr: Reconnecting previous active session(s)")

            reconnectionRetry += 1
            failureTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onFailureTimerExpiry), userInfo: nil, repeats: false)

            if !applicationControllers.isEmpty {
                driver?.connect(for: .application, with: currentApplicationData, onSuccess: {  self.resetFailureTimer() }, onError: { _ in })
            }

            if publicSettings != nil {
                driver?.connect(for: .publicSettings, with: currentApplicationData, onSuccess: {  self.resetFailureTimer() }, onError: { _ in })
            }

            if privateSettings != nil {
                driver?.connect(for: .privateSettings, with: currentApplicationData, onSuccess: {  self.resetFailureTimer() }, onError: { _ in })
            }
        }
    }
}
