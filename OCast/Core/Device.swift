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

/// Describes the device state.
///
/// - disconnected: The device is disconnected.
/// - connecting: The device is connecting.
/// - connected: The devices is connected.
/// - disconnecting: The device is disconnecting.
@objc
public enum DeviceState: Int {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/// The handler used to manage a result or an error.
public typealias ResultHandler<T> = (_ result: T?, _ error: Error?) -> ()

/// The handler used to manage an error.
public typealias NoResultHandler = (_ error: Error?) -> ()

/// The event handler used to manage custom events.
public typealias EventHandler = (_ data: Data) -> ()

/// The device representing the remote OCast device.
@objc
public protocol Device {
    
    // MARK: - Properties
    
    /// The application name. This property must be set to use media commands and events.
    var applicationName: String? { get set }
    
    /// The application URL.
    var applicationURL: String { get }
    
    /// The device IP address.
    var ipAddress: String { get }
    
    /// The device name.
    var friendlyName: String { get }
    
    /// The SSL configuration used if you want to perform a SSL connection.
    var sslConfiguration: SSLConfiguration { get }
    
    /// The manufacturer.
    var manufacturer: String { get }
    
    /// The search target used to discover the device.
    static var searchTarget: String { get }
    
    // MARK: - Initializer
    
    /// Initializes a new `Device` from an `UPNPDevice`.
    ///
    /// - Parameter upnpDevice: The `UPNPDevice` used to create the new `Device`.
    init(upnpDevice: UPNPDevice)
        
    // MARK: - Connection methods
    
    /// Connects to the device.
    ///
    /// - Parameters:
    ///   - configuration: The `SSLConfiguration` to parameter certificates.
    ///   - completion: The completion block called when the connection is finished.
    /// If the error is nil, the device is connected with success.
    func connect(_ configuration: SSLConfiguration, completion: @escaping NoResultHandler)
    
    /// Disconnects from the device.
    ///
    /// - Parameter completion: The completion block called when the disconnection is finished.
    /// If the error is nil, the device is disconnected with success.
    func disconnect(_ completion: @escaping NoResultHandler)
        
    // MARK: - Application methods
    
    /// Starts the application identified by `applicationName`.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the application is started.
    func startApplication(_ completion: @escaping NoResultHandler)
    
    /// Stops the application identified by `applicationName`.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the application is stopped.
    func stopApplication(_ completion: @escaping NoResultHandler)
    
    // MARK: - Events methods
    
    /// Registers a handler when the specifed event name is received.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - handler: The block called when the given events is received.
    func registerEvent(_ name: String, withHandler handler: @escaping EventHandler)
    
    // MARK: - Media commands
    
    /// Prepares to play a media.
    ///
    /// - Parameters:
    ///   - prepareCommand: The prepare parameters. See `MediaPrepareCommand`.
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully prepared.
    func prepare(_ prepareCommand: MediaPrepareCommand, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Sets a specific track.
    ///
    /// - Parameters:
    ///   - trackCommand: The track parameters. See `MediaTrackCommand`.
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the track was successfully set.
    func setTrack(_ trackCommand: MediaTrackCommand, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Plays a media at a specific position.
    ///
    /// - Parameters:
    ///   - position: The position in seconds.
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully played.
    func play(at position: Double, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Stops the current media.
    ///
    /// - Parameters:
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully stopped.
    func stop(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Resumes the current media.
    ///
    /// - Parameters:
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully resumed.
    func resume(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Sets the volume.
    ///
    /// - Parameters:
    ///   - volume: The volume level between 0 and 1.
    ///   - options: The command options (metadata, ...).
    ///   - completion:  The completion block called when the action completes.
    /// If the error is nil, the volume was successfully set.
    func setVolume(_ volume: Float, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Pauses the current media.
    ///
    /// - Parameters:
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully paused.
    func pause(withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Seeks the current media to a specified position.
    ///
    /// - Parameters:
    ///   - position: The position to which to seek.
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully seeked.
    func seek(to position: Double, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Retrieves the current media metadata.
    ///
    /// - Parameters:
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the metadata was successfully retrieved and is described in `MediaMetadata` parameter.
    func metadata(withOptions options: [String: Any]?, completion: @escaping ResultHandler<MediaMetadata>)
    
    /// Retrieves the current media playback status.
    ///
    /// - Parameters:
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the playback status was successfully retrieved and is described in `MediaPlaybackStatus` parameter.
    func playbackStatus(withOptions options: [String: Any]?, completion: @escaping ResultHandler<MediaPlaybackStatus>)
    
    /// Mutes or unmutes the current media.
    ///
    /// - Parameters:
    ///   - flag: `true` to mute the current media, `false` to unmute.
    ///   - options: The command options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully muted.
    func mute(_ flag: Bool, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    // MARK: - Settings commands methods
    
    /// Retrieves the device update status.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the update status was successfully retrieved and is described in `SettingsUpdateStatus` parameter.
    func updateStatus(_ completion: @escaping ResultHandler<SettingsUpdateStatus>)
    
    /// Retrieves the device id.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the device id was successfully retrieved and is described in `SettingsDeviceID` parameter.
    func deviceID(_ completion: @escaping ResultHandler<String>)
    
    // MARK: - Settings input commands methods
    
    /// Sends a key event.
    ///
    /// - Parameters:
    ///   - keyEvent: The key event parameter. See `SettingsKeyPressedCommand`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the key event was successfully sent.
    func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping NoResultHandler)
    
    /// Sends a mouse event.
    ///
    /// - Parameters:
    ///   - mouseEvent: The mouse event parameter. See `SettingsKeyPressedCommand`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the mouse event was successfully sent.
    func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping NoResultHandler)
    
    /// Sends a gamepad event.
    ///
    /// - Parameters:
    ///   - gamepadEvent: The gamepad event parameter. See `SettingsGamepadEventCommand`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the gamepad event was successfully sent.
    func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping NoResultHandler)
}

/// Extension to manage the custom streams.
public protocol OCastSenderDevice {
    
    /// Sends a message without a response to a specified domain.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - domain: The domain.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent.
    func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping NoResultHandler)
    
    /// Sends a message with a response to a specified domain.
    ///
    /// - Parameters:
    ///   - message: The message to send
    ///   - domain: The domain.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping ResultHandler<U>)
}

/// Extension to manage default parameter values (forbidden in a protocol).
public extension Device {
    
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func play(at position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func stop(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func resume(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func setVolume(_ volume: Float, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func pause(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func seek(to position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
    
    func metadata(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaMetadata>) {}
    
    func playbackStatus(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaPlaybackStatus>) {}
    
    func mute(_ flag: Bool, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {}
}
