//
// Copyright 2019 Orange
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
//  OCastDevice.swift
//  OCast
//
//  Created by Christophe Azemar on 06/12/2018.
//

import Foundation
import DynamicCodable

@objc
public protocol OCastDeviceDelegate {
    func device(_ device: OCastDevicePublic, didDisconnectWith error: Error?)
}

@objc
public enum DeviceState: Int {
    case connecting = 0
    case connected
    case disconnecting
    case idle
}

@objc
public protocol OCastDeviceProtocol : OCastSSDPDevice, OCastDevicePublic {}

@objc
public protocol OCastSSDPDevice {
    static var manufacturer: String { get }
    static var searchTarget: String { get }
}

public typealias CommandWithResultHandler<T> = (_ result: T?, _ error: Error?) -> ()
public typealias CommandWithoutResultHandler = (_ error:Error?) -> ()
public typealias EventHandler = (_ data: Data) -> ()

@objc
public protocol OCastDevicePublic {
    
    // Properties
    var applicationName: String? { get set }
    var ipAddress: String { get }
    var applicationURL: String { get }
    var sslConfiguration: SSLConfiguration { set get }
        
    init(ipAddress: String, applicationURL: String)
    // Connection
    func connect(withCompletion handler: CommandWithoutResultHandler?)
    func connect(withSSLConfiguration configuration: SSLConfiguration, completion handler: CommandWithoutResultHandler?)
    func disconnect(withCompletion handler: CommandWithoutResultHandler?)
    // Application
    func startApplicationWithCompletionHandler(_ handler: @escaping (_: Bool, _: Error?) -> ())
    func stopApplicationWithCompletionHandler(_ handler: @escaping (_: Bool, _: Error?) -> ())
    // Events
    func registerEvent(_ name: String, withHandler handler: @escaping EventHandler)
    // Media commands
    func prepare(_ command: MediaPrepareCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func track(_ command: MediaTrackCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func play(_ command: MediaPlayCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func stop(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func resume(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func volume(_ command: MediaVolumeCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func pause(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func seek(_ command: MediaSeekCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    func metadata(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithResultHandler<MediaMetadataChanged>)
    func playbackStatus(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithResultHandler<MediaPlaybackStatus>)
    func mute(_ isMuted: Bool, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    // Settings commands
    func updateStatusWithCompletionHandler(_ handler: @escaping CommandWithResultHandler<SettingsUpdateStatus>)
    func deviceIDWithCompletionHandler(_ handler: @escaping CommandWithResultHandler<SettingsDeviceID>)
    // Settings input commands
    func keyPressed(_ command: SettingsKeyPressedCommand, withCompletion handler: @escaping CommandWithoutResultHandler)
    func mouseEvent(_ command: SettingsMouseEventCommand, withCompletion handler: @escaping CommandWithoutResultHandler)
    func gamepadEvent(_ command: SettingsGamepadEventCommand, withCompletion handler: @escaping CommandWithoutResultHandler)
}

public protocol OCastDeviceCustom {
    // Custom commands
    func sendCustomCommand<T: OCastMessage>(name: String, forDomain domain: OCastDomainName, andService service: String, withParams params: T, andOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler)
    
    func sendCustomCommand<T: OCastMessage>(name: String, forDomain domain: OCastDomainName, andService service: String, withParams params: T, andOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithResultHandler<String>)
}
