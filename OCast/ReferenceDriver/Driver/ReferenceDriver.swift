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

/// Provides the Reference driver implementation.
@objcMembers
@objc open class ReferenceDriver: NSObject, Driver, LinkDelegate {
    
    /// Success and error callbacks
    private struct Callback {
        let success: () -> Void
        let error: (NSError?) -> Void
    }
    
    // MARK: - Public properties
    
    /// Target that matches with this driver.
    open static let searchTarget = "urn:cast-ocast-org:service:cast:1"
    
    /// Manufacturer name that matches with this driver.
    open static let manufacturer = "Orange SA"
    
    /// Reference driver error domain
    public static let referenceDriverErrorDomain = "ReferenceDriverErrorDomain"
    
    /// Browser delegate to receive events.
    public weak var browserEventDelegate: EventDelegate?
    
    /// Public settings delegate to receive events.
    public weak var publicSettingsEventDelegate: PublicSettingsEventDelegate?
    
    /// Links by module
    public private(set) var links: [DriverModule: Link] = [:]
    
    // MARK: - Private properties
    
    /// Device IP address.
    private var ipAddress: String
    
    /// SSL configuration.
    private var sslConfiguration: SSLConfiguration?
    
    /// Link states by module.
    private var linksState: [DriverModule: DriverState] = [:]
    
    /// Delegates by module.
    private var delegates: [DriverModule : DriverDelegate] = [:]
    
    /// Connection callbacks by module.
    private var connectCallbacks: [DriverModule: Callback] = [:]
    
    /// Disconnection callbacks by module.
    private var disconnectCallbacks: [DriverModule: Callback] = [:]
    
    // MARK: Public methods
    
    open func buildLink(profile: LinkProfile) -> Link? {
        return nil
    }
    
    // MARK: Private methods
    
    /// Appends the callbacks in a given dictionary to call several completion handlers in one call
    ///
    /// - Parameters:
    ///   - callbackDictionary: The dictionary to update.
    ///   - module: The module to update.
    ///   - newCallback: The new callback to append to the existing one.
    private func appendCallBack(in callbackDictionary: inout [DriverModule: Callback], for module: DriverModule, with newCallback: Callback) {
        let existingCallback = callbackDictionary[module]
        let updatedCallback = Callback(success: {
            existingCallback?.success()
            newCallback.success()
        }) { error in
            existingCallback?.error(error)
            newCallback.error(error)
        }
        callbackDictionary[module] = updatedCallback
    }
    
    /// Modules used by a link
    ///
    /// - Parameter link: The link to check.
    /// - Returns: An array of `DriverModule` to indicated in which module the link is used.
    private func modulesUsedBy(_ link: Link) -> [DriverModule] {
        return links.filter({ $0.value === link }).compactMap({ $0.key })
    }
    
    // MARK: - Driver methods
    
    public required init(ipAddress: String, with sslConfiguration: SSLConfiguration?) {
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
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: ReferenceDriverErrorCode.privateSettingsNotAllowed.rawValue, userInfo: nil)
            onError(error)
            return
        }
        
        switch state(for: module) {
        case .connected:
            onSuccess()
        case .connecting:
            appendCallBack(in: &connectCallbacks, for: module, with: Callback(success: onSuccess, error: onError))
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
                let linkProfile = LinkProfile(app2appURL: app2appURL ?? "", sslConfiguration: sslConfiguration)
                
                // Check if the same link is already existing in another module
                if let otherLink = links.first(where: { (_, l) -> Bool in
                    return l.profile.app2appURL == linkProfile.app2appURL
                }) {
                    
                    links[module] = otherLink.value
                    switch state(for: otherLink.key) {
                    case .connected:
                        linksState[module] = .connected
                        onSuccess()
                        return
                    case .connecting:
                        linksState[module] = .connecting
                        connectCallbacks[module] = Callback(success: onSuccess, error: onError)
                        return
                    default:
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
            connectCallbacks[module] = Callback(success: onSuccess, error: onError)
            linksState[module] = .connecting
            if !(link?.connect() ?? false) {
                links.removeValue(forKey: module)
                connectCallbacks.removeValue(forKey: module)
                linksState[module] = .disconnected
                let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: ReferenceDriverErrorCode.invalidApplicationURL.rawValue, userInfo: nil)
                onError(error)
            }
        }
    }
    
    open func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        guard let link = links[module] else {
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: ReferenceDriverErrorCode.moduleNotConnected.rawValue, userInfo: nil)
            onError(error)
            return
        }
        
        if linksState[module] == .disconnecting {
            appendCallBack(in: &disconnectCallbacks, for: module, with: Callback(success: onSuccess, error: onError))
            return
        }
        
        if !links.contains(where: { (entry) -> Bool in
            return entry.key != module && entry.value.profile.app2appURL == link.profile.app2appURL
        }) {
            linksState[module] = .disconnecting
            disconnectCallbacks[module] = Callback(success: onSuccess, error: onError)
            link.disconnect()
        } else {
            // We don't close the link
            linksState[module] = .disconnected
            links.removeValue(forKey: module)
            onSuccess()
        }
    }
    
    // MARK: - LinkDelegate methods
    
    open func linkDidConnect(_ link: Link) {
        let modules = modulesUsedBy(link)
        
        for module in modules {
            linksState[module] = .connected
            connectCallbacks[module]?.success()
            connectCallbacks.removeValue(forKey: module)
        }
    }
    
    open func link(_ link: Link, didDisconnectWith error: Error?) {
        let modules = modulesUsedBy(link)
        
        for module in modules {
            linksState[module] = .disconnected
            links.removeValue(forKey: module)
            
            // Connection error
            if let connectCallback = connectCallbacks[module] {
                connectCallback.error(error as NSError?)
                connectCallbacks.removeValue(forKey: module)
                continue
            }
            
            // Disconnection error
            if let disconnectCallback = disconnectCallbacks[module] {
                if error == nil {
                    disconnectCallback.success()
                } else {
                    disconnectCallback.error(error as NSError?)
                }
                disconnectCallbacks.removeValue(forKey: module)
                continue
            }
            
            // Connection lost during the session
            let newError = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: ReferenceDriverErrorCode.linkConnectionLost.rawValue, userInfo: nil)
            delegates[module]?.driver(self, didDisconnectModule: module, withError: newError)
        }
    }
    
    open func link(_ link: Link, didReceiveEvent event: Event) {
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
            let error = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: ReferenceDriverErrorCode.moduleNotConnected.rawValue, userInfo: nil)
            onError(error)
            return
        }
        
        let payload = Command(params: data)
        
        link.send(
            payload: payload,
            forDomain: ReferenceDomainName.browser.rawValue,
            onSuccess: { commandReply in
                onSuccess(commandReply.message)
        },
            onError: onError)
    }
    
    public func register(for browser: EventDelegate) {
        self.browserEventDelegate = browser
    }
}
