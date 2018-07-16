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

/// The delegate of a DeviceManager object must adopt the DeviceManagerDelegateDelegate protocol.
@objc public protocol DeviceManagerDelegate {
    
    /// Tells the delegate that the application is disconnected.
    ///
    /// - Parameters:
    ///   - deviceManager: The `DeviceManager`instance.
    ///   - error: The error.
    func deviceManager(_ deviceManager: DeviceManager, applicationDidDisconnectWithError error: NSError)
    
    /// Tells the delegate that the public settings is disconnected.
    ///
    /// - Parameters:
    ///   - deviceManager: The `DeviceManager`instance.
    ///   - error: The error.
    @objc optional func deviceManager(_ deviceManager: DeviceManager, publicSettingsDidDisconnectWithError error: NSError)
    
    /// Tells the delegate that the private settings is disconnected.
    ///
    /// - Parameters:
    ///   - deviceManager: The `DeviceManager`instance.
    ///   - error: The error.
    @objc optional func deviceManager(_ deviceManager: DeviceManager, privateSettingsDidDisconnectWithError error: NSError)
}

/**
 Device manager is used to get control over your device.
 ```
 deviceManager = DeviceManager(with: device, sslConfiguration: nil)
 ```

 */
@objcMembers
@objc public final class DeviceManager: NSObject, DriverDelegate, HttpProtocol {
    
    public weak var delegate: DeviceManagerDelegate?
    // Application controller
    private var applicationController: ApplicationController?
    // ssl
    private var sslConfiguration: SSLConfiguration?
    // drivers
    private var driver: Driver
    private static var registeredDrivers: [String: Driver.Type] = [:]
    public private(set) var device: Device

    // MARK: - Public interface
    /// Initializes a new DeviceManager.
    ///
    /// - Parameters:
    ///   - device: the device to be managed
    ///   - sslConfiguration: Optional. The SSL configuration to establish secured connections to the device.
    public init?(with device: Device, sslConfiguration: SSLConfiguration? = nil) {
        guard let driver = DeviceManager.driver(for: device, with: sslConfiguration) else { return nil }
        
        self.device = device
        self.sslConfiguration = sslConfiguration
        self.driver = driver
        
        super.init()
    }

    /// Used to get a reference to the publicSettingController class
    ///
    /// - Parameters:
    ///   - onSuccess: the closure to be called in case of success. Returns a reference to the publicSettingController.
    ///   - onError: the closure to be called in case of error
    public func publicSettingsController(onSuccess: @escaping (_: PublicSettings) -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        if driver.state(for: .publicSettings) == .connected, let driver = driver as? PublicSettings {
            onSuccess(driver)
            return
        }

        driver.register(self, forModule: .publicSettings)

        driver.connect(for: .publicSettings, with: nil,
                       onSuccess: {
                            if let publicSettingsCtrl = self.driver as? PublicSettings {
                                onSuccess(publicSettingsCtrl)
                            } else {
                                // TODO: create error
                                onError(nil)
                            }
                       },
                       onError: onError
        )
    }

    /// Used to release the reference to the publicSettingController class.
    ///
    /// - Parameters:
    ///   - onSuccess: the closure to be called in case of success.
    ///   - onError: the closure to be called in case of error
    public func releasePublicSettingsController(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        driver.disconnect(for: .publicSettings, onSuccess: onSuccess, onError: onError)
    }

    /// Used to get a reference to the privateSettingController class
    ///
    /// - Parameters:
    ///   - onSuccess: the closure to be called in case of success; Returns a reference to the privateSettingController.
    ///   - onError: the closure to be called in case of error
    public func privateSettingsController(onSuccess: @escaping (_: PrivateSettings) -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        if !driver.privateSettingsAllowed() {
            let newError = NSError(domain: "DeviceManager", code: 0, userInfo: ["Error": "Private settings are not available"])
            onError(newError)
            return
        }

        driver.register(self, forModule: .privateSettings)

        if driver.state(for: .privateSettings) == .connected, let driver = driver as? PrivateSettings {
            onSuccess(driver)
            return
        }

        driver.connect(for: .privateSettings, with: nil,
                       onSuccess: {
                            if let privateSettingsCtrl = self.driver as? PrivateSettings {
                                onSuccess(privateSettingsCtrl)
                            }  else {
                                // TODO: create error
                                onError(nil)
                            }
                       },
                       onError: onError
        )
    }

    /// Used to release the reference to the privateSettingController class.
    ///
    /// - Parameters:
    ///   - onSuccess: the closure to be called in case of success
    ///   - onError: the closure to be called in case of error
    public func releasePrivateSettingsController(onSuccess: @escaping () -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        driver.disconnect(for: .privateSettings, onSuccess: onSuccess, onError: onError)
    }

    /// Used to get a reference to the applicationController class
    ///
    /// - Parameters:
    ///   - applicationName: application's name
    ///   - onSuccess: the closure to be called in case of success. Returns a reference to the applicationController.
    ///   - onError: the closure to be called in case of error
    public func applicationController(for applicationName: String, onSuccess: @escaping (_: ApplicationController) -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        
        if let applicationController = applicationController,
            applicationController.applicationData.name == applicationName {
            
            onSuccess(applicationController)
            return
        }
        
        guard let target = self.target(from: device.baseURL, with: applicationName) else {
            onError(NSError(domain: "ErrorDomain", code: 0, userInfo: ["Error": "Bad target URL"]))
            return
        }

        applicationData(
            applicationName: applicationName,
            target: target,
            onSuccess: { [weak self] (description) in
                guard let `self` = self else { return }
                
                let newController = ApplicationController(for: self.device, with: description, target: target, driver: self.driver)
                self.driver.register(self, forModule: .application)
                self.applicationController = newController
                onSuccess(newController)
        },
            onError: {
                self.applicationController = nil
                onError($0)
            }
        )
    }
    
    /// Registers a driver to connect to a device.
    ///
    /// - Parameters:
    ///   - driverType: The Type of the driver class to register (for example ReferenceDriver.self)
    ///   - name: The Driver manufacturer's name. Caps sensitive. This value must match the manufacturer name present in the response to a MSEARCH Target.
    public static func registerDriver(_ driverType: Driver.Type, forManufacturer name: String) {
        registeredDrivers[name] = driverType
    }

    // MARK: - Private methods
    private static func driver(for device: Device, with sslConfiguration: SSLConfiguration?) -> Driver? {
        if let driverType = DeviceManager.registeredDrivers[device.manufacturer] {
            return driverType.init(ipAddress: device.ipAddress, with: sslConfiguration)
        } else {
            OCastLog.error("DeviceManager: Could not initialize the \(device.manufacturer) driver.")
            return nil
        }
    }
    
    private func target(from baseURL: URL?, with applicationName: String) -> String? {
        return baseURL?.appendingPathComponent(applicationName).absoluteString
    }

    private func applicationData(applicationName: String, target: String, onSuccess: @escaping (_ applicationDescription: ApplicationDescription) -> Void, onError: @escaping (_ error: NSError?) -> Void) {
        
        initiateHttpRequest(with: .get, to: target, onSuccess: { (response, data) in
            guard let data = data else {
                OCastLog.error("ApplicationMgr: No content to parse.")
                onError(NSError(domain: "ErrorDomain", code: 0, userInfo: ["Error": "No content to parse"]))
                return
            }
            
            let parserHelper = XMLHelper()
            parserHelper.completionHandler = {
                (error, keys, keysAttributes) in
                if error == nil {
                    let app2URL = keys?["ocast:X_OCAST_App2AppURL"]?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let newURL = app2URL?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let version = keys?["ocast:X_OCAST_Version"]?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let linkAttributes = keysAttributes?["link"]
                    let rel = linkAttributes?["rel"]
                    let href = linkAttributes?["href"]
                    let applicationDescription = ApplicationDescription(app2appURL: newURL, version: version ?? "", rel: rel, href: href, name: applicationName)
                    onSuccess(applicationDescription)
                } else {
                    onError(error as NSError?)
                }
            }
            parserHelper.parseDocument(data: data)
        }, onError: onError)
    }

    // MARK: DriverDelegate methods
    public func driver(_ driver: Driver, didDisconnectModule module: DriverModule, withError error: NSError) {
        switch module {
        case .application:
            applicationController = nil
            delegate?.deviceManager(self, applicationDidDisconnectWithError: error)
        case .publicSettings:
            delegate?.deviceManager?(self, publicSettingsDidDisconnectWithError: error)
        case .privateSettings:
            delegate?.deviceManager?(self, privateSettingsDidDisconnectWithError: error)
        }
    }

}
