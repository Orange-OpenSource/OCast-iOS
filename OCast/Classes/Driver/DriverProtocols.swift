//
// DriverProtocols.swift
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

// MARK: - Public Driver protocols
/// :nodoc:
@objc public protocol DriverPublicSettingsProtocol {
    // Not yet implemented on stick side. This getUpdateStatus() is given as an example.
    func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void)
}
/// :nodoc:
@objc public protocol DriverPrivateSettingsProtocol {
    // Not yet implemented on stick side
}

// MARK: - Internal Driver protocols

internal protocol DriverFactoryProtocol {
    func make(from sender: DriverProtocol, for ipAddress: String, with certificateInfo: CertificateInfo?) -> DriverProtocol
}

protocol DriverProtocol {
    func privateSettingsAllowed() -> Bool
    func connect(for module: DriverModule, with info: ApplicationDescription, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func disconnect(for module: DriverModule, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void)
    func getState(for module: DriverModule) -> DriverState
    func register(for delegate: DriverProtocol, with module: DriverModule)
    func onFailure(error: NSError?)
}

protocol DriverBrowserProtocol {
    func sendBrowserData(data: DriverDataStructure, onSuccess: @escaping (DriverDataStructure) -> Void, onError: @escaping (NSError?) -> Void)
    func onData(with data: DriverDataStructure)
    func registerBrowser(for browser: DriverBrowserProtocol)
}

// MARK: - Driver states

enum DriverState {
    case connecting
    case connected
    case disconnecting
    case disconnected
}

enum DriverModule {
    case application
    case privateSettings
    case publicSettings
}

// MARK: - Protocol default implementations

/// :nodoc:
public extension DriverPublicSettingsProtocol {
    // Not yet implemented on stick side
    func getUpdateStatus(onSuccess _: @escaping (StatusInfo) -> Void, onError _: @escaping (NSError?) -> Void) {}
}

/// :nodoc:
public extension DriverPrivateSettingsProtocol {
    // Not yet implemented on stick side
}

extension DriverProtocol {
    func privateSettingsAllowed() -> Bool { return false }
    func connect(for _: DriverModule, with _: ApplicationDescription, onSuccess _: @escaping () -> Void, onError _: @escaping (NSError?) -> Void) {}
    func disconnect(for _: DriverModule, onSuccess _: @escaping () -> Void, onError _: @escaping (NSError?) -> Void) {}
    func getState(for _: DriverModule) -> DriverState { return .disconnected }
    func register(for _: DriverProtocol, with _: DriverModule) {}
    func onFailure(error _: NSError?) {}
}

extension DriverBrowserProtocol {
    func sendBrowserData(data _: DriverDataStructure, onSuccess _: @escaping (DriverDataStructure) -> Void, onError _: @escaping (NSError?) -> Void) {}
    func onData(with _: DriverDataStructure) {}
    func registerBrowser(for _: DriverBrowserProtocol) {}
}
