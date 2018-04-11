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

   public func make(for ipAddress: String, with certificateInfo: CertificateInfo?) -> Driver {
        return ReferenceDriver(ipAddress: ipAddress, with: certificateInfo)
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
@objc public final class ReferenceDriver: NSObject, Driver, LinkDelegate {
    
    // MARK: - Public interface

    /*
     Caps sensitive.
     This value must match the manufacturer serach target (ST) present in the discovery response.
     */

    /// Read only. Target that matches with this driver.
    public static let searchTarget = "urn:cast-ocast-org:service:cast:1"

    /*  
     Caps sensitive.
     This value must match the manufacturer name present in the device description.
     */

    /// Read only. Manufacturer'name that matches with this driver.
    public static let manufacturer = "Orange SA"

    // MARK: - Internal

    var links: [LinkId: ReferenceLink] = [:]
    public var delegate: DriverReceiverDelegate?

    enum LinkId: Int8 {
        case genericLink
    }

    public func privateSettingsAllowed() -> Bool {
        return false
    }

    public func register(_ delegate: DriverDelegate, forModule module: DriverModule) {
        delegates[module] = delegate
    }

    public func getState(for _: DriverModule) -> DriverState {

        if linksState[LinkId.genericLink] == .connected {
            return .connected
        }

        return .disconnected
    }

   public func connect(for module: DriverModule, with info: ApplicationDescription, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {

        switch module {
        case .application:

            if links.count == 0 {
                let linkProfile = LinkProfile(identifier: LinkId.genericLink.rawValue, ipAddress: ipAddress, needsEvent: false, app2appURL: info.app2appURL, certInfo: nil)
                links = [LinkId.genericLink: ReferenceLink(from: self, profile: linkProfile)]
            }

            guard let genericLink = links[LinkId.genericLink] else {
                OCastLog.error(("Reference Driver: Could not get the link."))
                let error = NSError(domain: "Reference driver", code: 0, userInfo: ["Reference driver": "Could not get the link."])
                onError(error)
                return
            }

            guard let state = linksState[LinkId.genericLink] else {
                return
            }

            requestedModules[module] = true

            switch state {
            case .connected:
                OCastLog.debug("Reference Driver: Already connected. Ignoring request.")
                onSuccess()
                return

            case .connecting:
                OCastLog.debug("Reference Driver: Connection already in progress. Ignoring request.")
                return

            case .disconnected, .disconnecting:
                OCastLog.debug("Reference Driver: Connecting the link.")
                successConnect[module] = onSuccess
                linksState[LinkId.genericLink] = .connecting

                genericLink.connect()
            }

        case .publicSettings:
            OCastLog.error(("Reference Driver: Public Settings are not implemented. Ignoring this request."))
            let error = NSError(domain: "Reference driver", code: 1, userInfo: ["Reference driver": "Public Settings are not implemented. Ignoring this request."])
            onError(error)
        case .privateSettings:
            OCastLog.error(("Reference Driver: Private Settings are not implemented. Ignoring this request."))
            let error = NSError(domain: "Reference driver", code: 1, userInfo: ["Reference driver": "Private Settings are not implemented. Ignoring this request."])
            onError(error)
        }
    }

    public func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {

        switch module {
        case .application:

            guard let genericLink = links[LinkId.genericLink] else {
                OCastLog.error(("Reference Driver: Could not get the link."))
                let error = NSError(domain: "Reference driver", code: 0, userInfo: ["Reference driver": "Could not get the link."])
                onError(error)
                return
            }

            OCastLog.debug("Reference Driver: Connecting the link.")
            successDisconnect[module] = onSuccess

            requestedModules[module] = false

            if linksState[LinkId.genericLink] != .disconnected {
                linksState[LinkId.genericLink] = .disconnecting

                // Check if another module shares the same link. If yes, do not disconnect the link.

                switch module {
                case .application:

                    if requestedModules[DriverModule.publicSettings] == true {
                        onSuccess()
                        return
                    }

                case .publicSettings:

                    if requestedModules[DriverModule.application] == true {
                        onSuccess()
                        return
                    }

                default:
                    return
                }

                genericLink.disconnect()

            } else {
                OCastLog.debug("Reference driver generic link is already disconnected.")
                onSuccess()
            }

        case .publicSettings:
            OCastLog.error(("Reference Driver: Public Settings are not implemented. Ignoring this request."))
            let error = NSError(domain: "Reference driver", code: 1, userInfo: ["Reference driver": "Public Settings are not implemented. Ignoring this request."])
            onError(error)
        case .privateSettings:
            OCastLog.error(("Reference Driver: Private Settings are not implemented. Ignoring this request."))
            let error = NSError(domain: "Reference driver", code: 1, userInfo: ["Reference driver": "Private Settings are not implemented. Ignoring this request."])
            onError(error)
        }
    }

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Private interface

    private var ipAddress: String
    private var certificateInfo: CertificateInfo?

    private var onLinkConnect: () -> Void = {}
    private var onLinkDisconnect: () -> Void = {}

    private var delegates: [DriverModule : DriverDelegate] = [:]
    private var successConnect: [DriverModule: () -> Void] = [:]
    private var successDisconnect: [DriverModule: () -> Void] = [:]

    private var internalState: DriverState = .connected
    private var linksState: [LinkId: DriverState] = [:]

    private var requestedModules: [DriverModule: Bool] = [:]

    // MARK: - Initialization

    init(ipAddress: String, with certificateInfo: CertificateInfo?) {
        self.ipAddress = ipAddress
        self.certificateInfo = certificateInfo
        linksState[LinkId.genericLink] = .disconnected
    }

    // MARK: - Link Protocol
    public func onLinkConnected(from identifier: Int8) {

        guard let id = LinkId(rawValue: identifier) else {
            return
        }

        linksState[id] = .connected
        OCastLog.debug("Reference Driver: Link is connected.")

        successConnect[.publicSettings]?()
        successConnect[.application]?()
        successConnect.removeValue(forKey: .publicSettings)
        successConnect.removeValue(forKey: .application)
    }

    public func onLinkDisconnected(from identifier: Int8) {

        guard let id = LinkId(rawValue: identifier) else {
            return
        }

        OCastLog.debug("Reference Driver: Link is disconnected.")
        linksState[id] = .disconnected

        successDisconnect[.publicSettings]?()
        successDisconnect[.application]?()
        successDisconnect.removeValue(forKey: .publicSettings)
        successDisconnect.removeValue(forKey: .application)
    }

    public func onLinkFailure(from identifier: Int8) {
        OCastLog.debug(("Reference Driver: Unexpected link disconnection."))

        guard let _ = LinkId(rawValue: identifier) else {
            return
        }

        successConnect.removeAll()
        successDisconnect.removeAll()

        let newError = NSError(domain: "Reference driver", code: 0, userInfo: ["Error": "Unexpected link disconnection"])

        if identifier == LinkId.genericLink.rawValue {
            linksState[LinkId.genericLink] = .disconnected
            delegates[.application]?.onFailure(error: newError)
            delegates[.publicSettings]?.onFailure(error: newError)
        }

    }

    public func onEvent(payload: Event) {
        if payload.domain == "browser" {
            delegate?.onData(with: payload.message)
        }
    }
    
    // MARK: BrowserDelegate methods
    public func send(data: [String: Any], onSuccess: @escaping ([String: Any]) -> Void, onError: @escaping (NSError?) -> Void) {
        
        guard let link = links[LinkId.genericLink] else {
            OCastLog.error("Reference Driver: Could not get the generic link.")
            // TODO: create error
            onError(nil)
            return
        }
        
        let payload = Command(params: data)
        
        link.sendPayload(
            forDomain: ReferenceDomainName.browser.name(),
            withPayload: payload,
            onSuccess: {
                cmdResponse in
                    OCastLog.debug("Reference Driver: Payload sent.")
                    // TODO: Fix this
                    onSuccess(cmdResponse.reply as? [String: Any] ?? [:])
                },
            onError: {
                error in
                    if let error = error {
                        OCastLog.error("Reference Driver: Payload could not be sent: \(String(describing: error.userInfo[link.ErrorDomain]))")
                        onError(error)
                    }
            })
    }
    
    public func register(for browser: DriverReceiverDelegate) {
        self.delegate = browser
    }
}
