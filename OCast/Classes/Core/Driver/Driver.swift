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

// MARK: - Internal Driver protocols
/// :nodoc:
@objc public protocol DriverFactory: class {
    func make(for ipAddress: String, with certificateInfo: CertificateInfo?) -> Driver
}

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
    func didFail(module: DriverModule, withError error: NSError?)
}

/// :nodoc:
@objc public protocol EventDelegate {
    func didReceiveEvent(withMessage message: [String: Any])
}

/// :nodoc:
@objc public protocol Driver: BrowserDelegate {
    var browserEventDelegate: EventDelegate? { get set }
    func privateSettingsAllowed() -> Bool
    func connect(for module: DriverModule, with info: ApplicationDescription?, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func state(for module: DriverModule) -> DriverState
    func register(_ delegate: DriverDelegate, forModule module: DriverModule)
}






