//
// Driver.swift
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

// MARK: - Driver states
/// :nodoc:
@objc public enum DriverState:Int {
    case connecting = 0
    case connected
    case disconnecting
    case disconnected
}
/// :nodoc:
@objc public enum DriverModule:Int {
    case application = 0
    case privateSettings
    case publicSettings
}

@objc public protocol DriverDelegate {
    /// Called when driver's module has been disconnected
    ///
    /// - Parameters:
    ///   - driver: driver
    ///   - driverModule: module
    ///   - error: error which implies the disconnection
    func driver(_ driver: Driver, didDisconnectModule driverModule: DriverModule, withError error: NSError)
}

@objc public protocol EventDelegate {
    /// Called when the driver has received an event
    ///
    /// - Parameter message: event's message received.
    func didReceiveEvent(withMessage message: [String: Any])
}

/// :nodoc:
@objc public protocol Driver: BrowserDelegate {
    /// Init a driver for the specified ip address with (optional) ssl configuration
    ///
    /// - Parameters:
    ///   - ipAddress: ip adress of the device
    ///   - sslConfiguration: ssl configuration
    init(ipAddress: String, with sslConfiguration: SSLConfiguration?)
    /// event delegate for browser's event
    var browserEventDelegate: EventDelegate? { get set }
    /// Indicate if private settings are allow for this driver
    ///
    /// - Returns: true if allowed, false otherwise.
    func privateSettingsAllowed() -> Bool
    /// Connect the driver the specified module with application's description
    ///
    /// - Parameters:
    ///   - driverModule: module to connect
    ///   - info: application's description
    ///   - onSuccess: handler called if connect is a success
    ///   - onError: handler called if there is an error
    func connect(for driverModule: DriverModule, with info: ApplicationDescription?, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    /// Disconnect the specified module
    ///
    /// - Parameters:
    ///   - driverModule: module to disconnect
    ///   - onSuccess: handler called if connect is a success
    ///   - onError: handler called if there is an error
    func disconnect(for driverModule: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    /// Returns the connection's state of the specified module
    ///
    /// - Parameter driverModule: module
    /// - Returns: state
    func state(for driverModule: DriverModule) -> DriverState
    /// Register a delegate for the specified module
    ///
    /// - Parameters:
    ///   - delegate: delegate
    ///   - driverModule: module
    func register(_ delegate: DriverDelegate, forModule driverModule: DriverModule)
}






