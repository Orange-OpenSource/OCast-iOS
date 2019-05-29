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

@objc
/// Describe the device's state
///
/// - disconnected: disconnected
/// - connecting: connecting in progress
/// - connected: connected
/// - disconnecting: disconnecting in progress
public enum DeviceState: Int {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

@objc
/// Device
public protocol OCastDeviceProtocol : OCastSSDPDevice, OCastDevicePublic {}

@objc
/// SSDP Device
public protocol OCastSSDPDevice {
    static var manufacturer: String { get }
    static var searchTarget: String { get }
}

public typealias CommandWithResultHandler<T> = (_ result: T?, _ error: Error?) -> () // ResultHandler
public typealias CommandWithoutResultHandler = (_ error: Error?) -> ()// NoResultHandler
public typealias EventHandler = (_ data: Data) -> ()

@objc
// TODO: renommer en OCastDevice quand on aura viré le SDK v1
public protocol OCastDevicePublic {
    
    // Properties
    var applicationName: String? { get set }
    var ipAddress: String { get }
    var applicationURL: String { get }
    var friendlyName: String { get }
    var sslConfiguration: SSLConfiguration { set get }
    
    init(upnpDevice: UPNPDevice)
        
    // MARK: Connection
    /// Connect to the websocket (app2app if applicationName is setted, settings otherwise)
    ///
    /// - Parameters:
    ///   - configuration: ssl configuration (certificates, ...)
    ///   - completion: completion called when connect is finished
    func connect(_ configuration: SSLConfiguration, completion: @escaping CommandWithoutResultHandler)
    /// Disconnect from the websocket
    ///
    /// - Parameter completion: completion called when disconnect is finished
    func disconnect(_ completion: @escaping CommandWithoutResultHandler)
        
    // MARK: Application
    /// Start the application identified by `applicationName`
    ///
    /// - Parameter completion: completion called at the end of the start process
    func startApplication(_ completion: @escaping CommandWithoutResultHandler)
    /// Stop the application identified by `applicationName`
    ///
    /// - Parameter completion: completion called at the end of the stop process
    func stopApplication(_ completion: @escaping CommandWithoutResultHandler)
    
    // MARK: Events
    /// Register a handler when the specifed event name is received
    ///
    /// - Parameters:
    ///   - name: name of the event
    ///   - handler: handler called when the event is received
    func registerEvent(_ name: String, withHandler handler: @escaping EventHandler)
    
    // MARK: Media commands
    /// Send a prepare command which permitt to cast a content
    ///
    /// - Parameters:
    ///   - prepare: command description
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Set a specific track
    ///
    /// - Parameters:
    ///   - track: command's description
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Play a content at a specific position
    ///
    /// - Parameters:
    ///   - position: position
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func play(at position: Double, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Stop the content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func stop(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Resume
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func resume(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Change the volume's level
    ///
    /// - Parameters:
    ///   - volume: volume level
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func setVolume(_ volume: Float, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Pause
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func pause(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Seek to the specified position
    ///
    /// - Parameters:
    ///   - position: position
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func seek(to position: Double, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    /// Retrieve metadata of the current content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func metadata(withOptions options: [String: Any]?, completion: @escaping CommandWithResultHandler<MediaMetadataChanged>)
    /// Retrieve the playback status of the current content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func playbackStatus(withOptions options: [String: Any]?, completion: @escaping CommandWithResultHandler<MediaPlaybackStatus>)
    /// mute (or not) the sound
    ///
    /// - Parameters:
    ///   - flag: `true` to mute, `false` to unmute
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func mute(_ flag: Bool, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    
    // MARK: Settings commands
    /// Retrieve the update's status of the device
    ///
    /// - Parameter completion: completion
    func updateStatus(_ completion: @escaping CommandWithResultHandler<SettingsUpdateStatus>)
    /// Retrive the device id of the device
    ///
    /// - Parameter completion: completion
    func deviceID(_ completion: @escaping CommandWithResultHandler<SettingsDeviceID>)
    
    // MARK: Settings input commands
    /// Send a key event
    ///
    /// - Parameters:
    ///   - keyEvent: key event description
    ///   - completion: completion
    func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping CommandWithoutResultHandler)
    /// Send a mouse event
    ///
    /// - Parameters:
    ///   - mouseEvent: mouse event description
    ///   - completion: completion
    func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping CommandWithoutResultHandler)
    /// Send a gamepad event
    ///
    /// - Parameters:
    ///   - gamepadEvent: gamepad event description
    ///   - completion: completion
    func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping CommandWithoutResultHandler)
}

public protocol OCastSenderDevice {
    
    /// Send a message to specified domain, response without content is expected
    ///
    /// - Parameters:
    ///   - message: message to send
    ///   - domain: domain
    ///   - completion: completion
    func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping CommandWithoutResultHandler)
    /// Send a message to specified domain, response with a content is expected
    ///
    /// - Parameters:
    ///   - message: message to send
    ///   - domain: domain
    ///   - completion: completion
    func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping CommandWithResultHandler<U>)
}

/// Extension to manage default parameter values (forbidden in a protocol)
public extension OCastDevicePublic {
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func play(at position: Double, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func stop(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func resume(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func setVolume(_ volume: Float, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func pause(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func seek(to position: Double, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
    func metadata(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithResultHandler<MediaMetadataChanged>) {}
    func playbackStatus(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithResultHandler<MediaPlaybackStatus>) {}
    func mute(_ flag: Bool, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {}
}
