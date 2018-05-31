//
//  ReferenceDriver.swift
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
//

import Foundation

@objcMembers
@objc public final class ReferenceDriverFactory: NSObject, DriverFactory {

    public static let shared = ReferenceDriverFactory()

    private override init() {
        // private initializer to force the use of the singleton instance
    }

   public func make(for ipAddress: String, with sslConfiguration: SSLConfiguration?) -> Driver {
        return ReferenceDriver(ipAddress: ipAddress, with: sslConfiguration)
    }
}

/**
 Provides the Reference driver implementation.
 The driver needs to be registered by the application as shonw below:

 ```
 DeviceManager.registerDriver(forName: ReferenceDriver.manufacturer, withFactory: ReferenceDriverFactory.sharedInstance)
 ```

 */
@objcMembers
@objc open class ReferenceDriver: NSObject, Driver, LinkDelegate {
    
    // MARK: - Public interface

    /*
     Caps sensitive.
     This value must match the manufacturer serach target (ST) present in the discovery response.
     */

    /// Read only. Target that matches with this driver.
    open static let searchTarget = "urn:cast-ocast-org:service:cast:1"

    /*  
     Caps sensitive.
     This value must match the manufacturer name present in the device description.
     */

    /// Read only. Manufacturer'name that matches with this driver.
    open static let manufacturer = "Orange SA"
    
    public static let ReferenceDriverErrorDomain = "ReferenceDriverErrorDomain"

    // MARK: - public
    public var browserEventDelegate: EventDelegate?
    public var publicSettingsEventDelegate: PublicSettingsEventDelegate?
    

    // MARK: - Private interface
    private var ipAddress: String
    private var sslConfiguration: SSLConfiguration?
    
    public private(set) var links: [DriverModule: Link] = [:]
    private var linksState: [DriverModule: DriverState] = [:]
    
    private var delegates: [DriverModule : DriverDelegate] = [:]
    private var successConnect: [DriverModule: () -> Void] = [:]
    private var successDisconnect: [DriverModule: () -> Void] = [:]
    
    // MARK: - Initialization
    public init(ipAddress: String, with sslConfiguration: SSLConfiguration?) {
        self.ipAddress = ipAddress
        self.sslConfiguration = sslConfiguration
        linksState[.application] = .disconnected
        linksState[.publicSettings] = .disconnected
        linksState[.privateSettings] = .disconnected
    }

    open func privateSettingsAllowed() -> Bool {
        return false
    }

    public func register(_ delegate: DriverDelegate, forModule module: DriverModule) {
        delegates[module] = delegate
    }

    public func state(for module: DriverModule) -> DriverState {
        return linksState[module] ?? .disconnected
    }

    open func connect(for module: DriverModule, with info: ApplicationDescription?, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {

        if module == .privateSettings && !privateSettingsAllowed() {
            OCastLog.error(("Reference Driver: Private Settings are not implemented in reference driver"))
            let error = NSError(domain: "Reference driver", code: 1, userInfo: ["Reference driver": "Private Settings are not implemented in reference driver"])
            onError(error)
        }

        switch state(for: module) {
            case .connected:
                onSuccess()
        
            case .connecting:
                OCastLog.debug("Link is already connecting.")
                let otherCallback = successConnect[module]
                successConnect[module] = { () in
                    otherCallback?()
                    onSuccess()
                }
                return
            case .disconnected, .disconnecting:
                var link = links[module]
                if link == nil {
                    var app2appURL:String?
                    // Settings ou Cavium
                    if info?.app2appURL == nil {
                        app2appURL = "wss://\(ipAddress):4433/ocast"
                    } else {
                        app2appURL = info?.app2appURL
                    }
                    let linkProfile = LinkProfile(
                        module: module,
                        app2appURL: app2appURL ?? "",
                        sslConfiguration: sslConfiguration)
                    
                    // Check if the same link is already existing in another module
                    if let otherLink = links.first(where: { (_, l) -> Bool in
                        return l.profile.app2appURL == linkProfile.app2appURL
                    }) {
                        
                        links[module] = otherLink.value
                        switch state(for: otherLink.key) {
                        case .connected:
                            // do nothing, call onSuccess
                            linksState[module] = .connected
                            onSuccess()
                            return
                        case .connecting:
                            // override the other callbacks
                            linksState[module] = .connecting
                            let otherSuccessCallback = successConnect[otherLink.key]
                            successConnect[otherLink.key] = { () in
                                otherSuccessCallback?()
                                onSuccess()
                            }
                            return
                        default:
                            // reconnect the link
                            link = otherLink.value
                        }
                    } else {
                        // Build a new link
                        link = buildLink(profile: linkProfile)
                        if link == nil {
                            link = ReferenceLink(withDelegate: self, andProfile: linkProfile)
                        }
                    }
                    
                }
                links[module] = link
                successConnect[module] = onSuccess
                linksState[module] = .connecting
                link?.connect()
        }
    }

    open func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        
        guard let link = links[module] else {
            let error = NSError(domain: ReferenceDriver.ReferenceDriverErrorDomain, code: 0, userInfo: ["Error": "Could not get the link."])
            onError(error)
            return
        }
        
        if linksState[module] == .disconnecting {
            // add the onSuccess callback to the existing callback
            let otherSuccessCallback = successDisconnect[module]
            successDisconnect[module] = { () in
                otherSuccessCallback?()
                onSuccess()
            }
            return
        }

        if !links.contains(where: { (entry) -> Bool in
            return entry.key != module && entry.value.profile.app2appURL == link.profile.app2appURL
        }) {
            linksState[module] = .disconnecting
            successDisconnect[module] = onSuccess
            link.disconnect()
        } else {
            // We don't close the link
            linksState[module] = .disconnected
            links.removeValue(forKey: module)
            // FIXME : onError or onSuccess ?
            onSuccess()
        }
    }
    
    // MARK: Internal methods
    open func buildLink(profile: LinkProfile) -> Link? {
        return nil
    }

    // MARK: - Link Protocol
    open func didConnect(module: DriverModule) {
        OCastLog.debug("Reference Driver: Link is connected.")
        linksState[module] = .connected
        successConnect[module]?()
        successConnect.removeValue(forKey: module)
    }

    open func didDisconnect(module: DriverModule) {
        OCastLog.debug("Reference Driver: Link is disconnected.")
        linksState[module] = .disconnected
        links.removeValue(forKey: module)
        successDisconnect[module]?()
        successDisconnect.removeValue(forKey: module)
    }

    open func didFail(module: DriverModule) {
        OCastLog.debug(("Reference Driver: Unexpected link disconnection."))
        successConnect.removeValue(forKey: module)
        successDisconnect.removeValue(forKey: module)
        linksState[module] = .disconnected
        links[module]?.disconnect()
        links.removeValue(forKey: module)
        let newError = NSError(domain: "Reference driver", code: 0, userInfo: ["Error": "Unexpected link disconnection"])
        delegates[module]?.didFail(module: module, withError: newError)
    }

    open func didReceive(event: Event) {
        if event.source == ReferenceDomainName.browser.rawValue {
            browserEventDelegate?.didReceiveEvent(withMessage: event.message)
        } else if event.source == ReferenceDomainName.settings.rawValue {
            
            if let service = event.message["service"] as? String,
                service == PublicSettingsConstants.SERVICE_SETTINGS_DEVICE {
                    didReceivePublicSettingsEvent(withMessage: event.message)
            } else if
                privateSettingsAllowed(),
                let privateSettings = self as? PrivateSettings {
                    privateSettings.didReceivePrivateSettingsEvent(withMessage: event.message)
            }
        }
    }
    
    // MARK: BrowserDelegate methods
    open func send(data: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {
        
        guard let link = links[.application] else {
            let error = NSError(domain: ReferenceDriver.ReferenceDriverErrorDomain, code: 0, userInfo: ["Error": "Link doesn't exists."])
            onError(error)
            return
        }
        
        let payload = Command(params: data)
        
        link.send(
            payload: payload,
            forDomain: ReferenceDomainName.browser.rawValue,
            onSuccess: {
                commandReply in
                    onSuccess(commandReply.message)
            },
            onError: {
                error in
                    if let error = error {
                        OCastLog.error("Reference Driver: Payload could not be sent: \(String(describing: error.userInfo[ReferenceDriver.ReferenceDriverErrorDomain]))")
                        onError(error)
                    }
            })
    }
    
    public func register(for browser: EventDelegate) {
        self.browserEventDelegate = browser
    }
}
