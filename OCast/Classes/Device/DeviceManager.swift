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

@objc public protocol DeviceManagerProtocol {
    func onFailure(error: NSError)
}

/**
 Device manager is used to get control over your device.
 ```
 deviceManager = DeviceManager (from: self, with: device, withCertificateInfo: nil)
 ```

 */
@objcMembers
@objc public final class DeviceManager: NSObject, DriverProtocol, HttpProtocol, XMLHelperProtocol {
    

    // MARK: - Public interface

    /**
     Initializes a new DeviceManager.

     - Parameters:
         - sender: module that will receive further notifications
         - device: the device to be managed
         - certificateInfo: Optional. An array of certificates to establish secured connections to the device.
     */

    public init? (from sender: Any, with device: Device, withCertificateInfo certificateInfo: CertificateInfo?) {

        delegate = sender
        managedDevice = device
        self.certificateInfo = certificateInfo
        super.init()

        guard let _ = self.getDriver(for: device) else {
            return nil
        }
    }

    /**
     Not implemented in this version.
     
     
     Used to get a reference to the publicSettingController class
     - Parameters:
         - onSuccess: the closure to be called in case of success. Returns a reference to the publicSettingController.
         - onError: the closure to be called in case of error
     */

    public func getPublicSettingsController(onSuccess: @escaping (_: DriverPublicSettingsProtocol) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        guard let driver = driver else {
            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Driver is not created."])
            onError(newError)
            return
        }

        if driver.getState(for: .publicSettings) == .connected {
            onSuccess(driver as! DriverPublicSettingsProtocol)
            return
        }

        driver.register(for: self, with: .publicSettings)

        currentApplicationData = ApplicationDescription(app2appURL: "", version: "", rel: "", href: "", name: "")

        driver.connect(for: .publicSettings, with: currentApplicationData,
                       onSuccess: {
                           self.publicSettingsCtrl = driver as? DriverPublicSettingsProtocol
                           onSuccess(driver as! DriverPublicSettingsProtocol)
                       },

                       onError: { error in onError(error) }
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

    public func getPrivateSettingsController(onSuccess: @escaping (_: DriverPrivateSettingsProtocol) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

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

        driver.register(for: self, with: .privateSettings)

        if driver.getState(for: .privateSettings) == .connected {
            onSuccess(driver as! DriverPrivateSettingsProtocol)
            return
        }

        currentApplicationData = ApplicationDescription(app2appURL: "", version: "", rel: "", href: "", name: "")

        driver.connect(for: .privateSettings, with: currentApplicationData,
                       onSuccess: {
                           self.privateSettingsCtrl = driver as? DriverPrivateSettingsProtocol
                           onSuccess(driver as! DriverPrivateSettingsProtocol)
                       },

                       onError: { error in onError(error) }
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

    public func getApplicationController(for applicationName: String, onSuccess: @escaping (_: ApplicationController) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        let duplicateController = applicationControllers.filter { appliCtrl -> Bool in
            return appliCtrl.applicationData.name == applicationName
        }

        if !duplicateController.isEmpty {
            onSuccess(duplicateController.first!)
            return
        }

        currentApplicationName = applicationName
        currentTarget = "\(managedDevice.baseURL)/\(applicationName)"

        getApplicationData(
            onSuccess: {
                let newController = ApplicationController(for: self.managedDevice, with: self.currentApplicationData, andDriver: self.driver)
                self.driver?.register(for: self, with: .application)
                self.applicationControllers.append(newController)
                onSuccess(newController)
            },

            onError: { error in onError(error) }
        )
    }

    /**
     Registers a driver to connect to a device.

     - Parameters:
        - name: Driver manufacturer's name. Caps sensitive. This value must match the manufacturer name present in the response to a MSEARCH Target.
        - factory: The factory instance that is in chrage of buildng a driver instance.
     */

  
   public static func registerDriver(forName name: String, factory: DriverFactoryProtocol) -> Bool {
        registeredDriver[name] = factory
        return true
    }
    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Internal

    var currentTarget: String!
    var currentApplicationData: ApplicationDescription!
    var currentApplicationName: String!
    var applicationControllers: [ApplicationController] = []
    var successCallback: () -> Void = {  }
    var errorCallback: (_ error: NSError?) -> Void = { _ in }

    var managedDevice: Device
    var driver: DriverProtocol?

    var delegate: Any

    var publicSettingsCtrl: DriverPublicSettingsProtocol?
    var privateSettingsCtrl: DriverPrivateSettingsProtocol?
    var certificateInfo: CertificateInfo?

    var reconnectionRetry: Int8 = 0
    let maxReconnectionRetry: Int8 = 5
    var failureTimer = Timer()

    static var registeredDriver: [String: DriverFactoryProtocol] = [:]

    // MARK: - Private methods

    func getDriver(for device: Device) -> DriverProtocol? {

        if let factory = DeviceManager.registeredDriver[device.manufacturer] {
            driver = factory.make(from: self, for: device.ipAddress, with: certificateInfo)
        } else {
            OCastLog.error("DeviceManager: Could not initialize the \(device.manufacturer) driver.")
            driver = nil
        }

        return driver
    }

    func resetAllContexts() {

        _ = applicationControllers.map { controller in
            controller.reset()
        }

        applicationControllers.removeAll()
        publicSettingsCtrl = nil
        privateSettingsCtrl = nil
    }

    func getApplicationData(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
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

        let parserHelper = XMLHelper(fromSender: self, for: currentTarget)

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

    // MARK: Driver Protocol

    public func onFailure(error _: NSError?) {
        OCastLog.debug("DeviceMgr: Received a Driver failure indication.")
        reconnectAllSessions()
    }
    
    // Default implementation - Should be implemented by the driver.
    
    public func privateSettingsAllowed() -> Bool {return false}
    public func connect(for module: DriverModule, with info: ApplicationDescription, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {}
    public func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {}
    public func getState(for module: DriverModule) -> DriverState {return .disconnected}
    public func register(for delegate: DriverProtocol, with module: DriverModule) {}

   // MARK: Miscellaneous
    
    @objc func onFailureTimerExpiry(timer _: Timer) {
        OCastLog.debug("DeviceMgr: onFailureTimerExpiry")

        if reconnectionRetry == maxReconnectionRetry {
            OCastLog.debug("DeviceMgr: Max reconnection retry is reached. Stopping retry process.")

            resetFailureTimer()
            resetAllContexts()

            if let delegate = self.delegate as? DeviceManagerProtocol {
                let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Driver is disconnected."])
                delegate.onFailure(error: newError)
            }
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

            if publicSettingsCtrl != nil {
                driver?.connect(for: .publicSettings, with: currentApplicationData, onSuccess: {  self.resetFailureTimer() }, onError: { _ in })
            }

            if privateSettingsCtrl != nil {
                driver?.connect(for: .privateSettings, with: currentApplicationData, onSuccess: {  self.resetFailureTimer() }, onError: { _ in })
            }
        }
    }
}
