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
public protocol DeviceProtocol : SSDPDevice, DevicePublic {}

@objc
/// SSDP Device
public protocol SSDPDevice {
    static var manufacturer: String { get }
    static var searchTarget: String { get }
}

public typealias ResultHandler<T> = (_ result: T?, _ error: Error?) -> ()
public typealias NoResultHandler = (_ error: Error?) -> ()
public typealias EventHandler = (_ data: Data) -> ()

@objc
public protocol DevicePublic {
    
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
    func connect(_ configuration: SSLConfiguration, completion: @escaping NoResultHandler)
    /// Disconnect from the websocket
    ///
    /// - Parameter completion: completion called when disconnect is finished
    func disconnect(_ completion: @escaping NoResultHandler)
        
    // MARK: Application
    /// Start the application identified by `applicationName`
    ///
    /// - Parameter completion: completion called at the end of the start process
    func startApplication(_ completion: @escaping NoResultHandler)
    /// Stop the application identified by `applicationName`
    ///
    /// - Parameter completion: completion called at the end of the stop process
    func stopApplication(_ completion: @escaping NoResultHandler)
    
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
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Set a specific track
    ///
    /// - Parameters:
    ///   - track: command's description
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Play a content at a specific position
    ///
    /// - Parameters:
    ///   - position: position
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func play(at position: Double, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Stop the content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func stop(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Resume
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func resume(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Change the volume's level
    ///
    /// - Parameters:
    ///   - volume: volume level
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func setVolume(_ volume: Float, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Pause
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func pause(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Seek to the specified position
    ///
    /// - Parameters:
    ///   - position: position
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func seek(to position: Double, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    /// Retrieve metadata of the current content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func metadata(withOptions options: [String: Any]?, completion: @escaping ResultHandler<MediaMetadataChanged>)
    /// Retrieve the playback status of the current content
    ///
    /// - Parameters:
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func playbackStatus(withOptions options: [String: Any]?, completion: @escaping ResultHandler<MediaPlaybackStatus>)
    /// mute (or not) the sound
    ///
    /// - Parameters:
    ///   - flag: `true` to mute, `false` to unmute
    ///   - options: command's options (metadata, ...)
    ///   - completion: completion
    func mute(_ flag: Bool, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    // MARK: Settings commands
    /// Retrieve the update's status of the device
    ///
    /// - Parameter completion: completion
    func updateStatus(_ completion: @escaping ResultHandler<SettingsUpdateStatus>)
    /// Retrive the device id of the device
    ///
    /// - Parameter completion: completion
    func deviceID(_ completion: @escaping ResultHandler<SettingsDeviceID>)
    
    // MARK: Settings input commands
    /// Send a key event
    ///
    /// - Parameters:
    ///   - keyEvent: key event description
    ///   - completion: completion
    func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping NoResultHandler)
    /// Send a mouse event
    ///
    /// - Parameters:
    ///   - mouseEvent: mouse event description
    ///   - completion: completion
    func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping NoResultHandler)
    /// Send a gamepad event
    ///
    /// - Parameters:
    ///   - gamepadEvent: gamepad event description
    ///   - completion: completion
    func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping NoResultHandler)
}

public protocol OCastSenderDevice {
    
    /// Send a message to specified domain, response without content is expected
    ///
    /// - Parameters:
    ///   - message: message to send
    ///   - domain: domain
    ///   - completion: completion
    func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping NoResultHandler)
    /// Send a message to specified domain, response with a content is expected
    ///
    /// - Parameters:
    ///   - message: message to send
    ///   - domain: domain
    ///   - completion: completion
    func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping ResultHandler<U>)
}

/// Extension to manage default parameter values (forbidden in a protocol)
public extension DevicePublic {
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func play(at position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func stop(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func resume(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func setVolume(_ volume: Float, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func pause(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func seek(to position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    func metadata(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaMetadataChanged>) {}
    func playbackStatus(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaPlaybackStatus>) {}
    func mute(_ flag: Bool, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
}
