//
// Device.swift
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
// limitations under the License.
//

import Foundation

/// The device states.
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
public typealias ResultHandler<T> = (_ result: T?, _ error: Error?) -> Void

/// The handler used to manage an error.
public typealias NoResultHandler = (_ error: Error?) -> Void

/// The event handler used to manage custom events.
public typealias EventHandler = (_ data: Data) -> Void

/// The device representing the remote OCast device.
@objc
public protocol Device {
    
    // MARK: - Properties
    
    /// The application name. This property must be set to use the media API.
    var applicationName: String? { get set }
    
    /// The UPNP device ID.
    var upnpID: String { get }
    
    /// The host or the IP address.
    var host: String { get }
    
    /// The device name.
    var friendlyName: String { get }
    
    /// The model name.
    var modelName: String { get }
    
    /// The device state.
    var state: DeviceState { get }
    
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
    ///   - sslConfiguration: The `SSLConfiguration` parameter certificates if you use a secure websocket.
    ///   - completion: The completion block called when the connection is finished.
    /// If the error is nil, the device is connected with success.
    func connect(_ sslConfiguration: SSLConfiguration?, completion: @escaping NoResultHandler)
    
    /// Disconnects from the device.
    ///
    /// - Parameter completion: The completion block called when the disconnection is finished.
    /// If the error is nil, the device is disconnected with success.
    func disconnect(completion: NoResultHandler?)
        
    // MARK: - Application methods
    
    /// Starts the application identified by `applicationName`.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the application is started.
    func startApplication(completion: @escaping NoResultHandler)
    
    /// Stops the application identified by `applicationName`.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the application is stopped.
    func stopApplication(completion: @escaping NoResultHandler)
    
    // MARK: - Events methods
    
    /// Registers a handler when the specifed event name is received.
    /// - Warning: The completion block is not called on the main thread.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - completion: The completion block called when the given events is received.
    func registerEvent(_ name: String, completion: @escaping EventHandler)
    
    // MARK: - Media methods
    
    /// Prepares to play a media.
    ///
    /// - Parameters:
    ///   - params: The prepare parameters. See `PrepareMediaCommandParams`.
    ///   - options: The options (metadata, ...).
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully prepared.
    func prepareMedia(_ params: PrepareMediaCommandParams, withOptions options: [String: Any]?, completion: @escaping NoResultHandler)
    
    /// Sets a specific track.
    ///
    /// - Parameters:
    ///   - params: The track parameters. See `SetMediaTrackCommandParams`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the track was successfully set.
    func setMediaTrack(_ params: SetMediaTrackCommandParams, completion: @escaping NoResultHandler)
    
    /// Plays a media at a specific position.
    ///
    /// - Parameters:
    ///   - position: The position in seconds.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully played.
    func playMedia(at position: Double, completion: @escaping NoResultHandler)
    
    /// Stops the current media.
    ///
    /// - Parameters:
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully stopped.
    func stopMedia(completion: @escaping NoResultHandler)
    
    /// Resumes the current media.
    ///
    /// - Parameters:
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully resumed.
    func resumeMedia(completion: @escaping NoResultHandler)
    
    /// Sets the volume.
    ///
    /// - Parameters:
    ///   - volume: The volume level between 0 and 1.
    ///   - completion:  The completion block called when the action completes.
    /// If the error is nil, the volume was successfully set.
    func setMediaVolume(_ volume: Double, completion: @escaping NoResultHandler)
    
    /// Pauses the current media.
    ///
    /// - Parameters:
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully paused.
    func pauseMedia(completion: @escaping NoResultHandler)
    
    /// Seeks the current media to a specified position.
    ///
    /// - Parameters:
    ///   - position: The position to which to seek.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully seeked.
    func seekMedia(to position: Double, completion: @escaping NoResultHandler)
    
    /// Retrieves the current media metadata.
    ///
    /// - Parameters:
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the metadata was successfully retrieved and is described in `MediaMetadata` parameter.
    func mediaMetadata(completion: @escaping ResultHandler<MediaMetadata>)
    
    /// Retrieves the current media playback status.
    ///
    /// - Parameters:
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the playback status was successfully retrieved and is described in `MediaPlaybackStatus` parameter.
    func mediaPlaybackStatus(completion: @escaping ResultHandler<MediaPlaybackStatus>)
    
    /// Mutes or unmutes the current media.
    ///
    /// - Parameters:
    ///   - flag: `true` to mute the current media, `false` to unmute.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the media was successfully muted.
    func muteMedia(_ flag: Bool, completion: @escaping NoResultHandler)
    
    // MARK: - Settings methods
    
    /// Retrieves the device update status.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the update status was successfully retrieved and is described in `UpdateStatus` parameter.
    func updateStatus(completion: @escaping ResultHandler<UpdateStatus>)
    
    /// Retrieves the device identifier.
    ///
    /// - Parameter completion: The completion block called when the action completes.
    /// If the error is nil, the device id was successfully retrieved and is described in `String` parameter.
    func deviceID(completion: @escaping ResultHandler<String>)
    
    // MARK: - Settings input methods
    
    /// Sends a key event.
    ///
    /// - Parameters:
    ///   - params: The key event parameters. See `SendKeyEventCommandParams`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the key event was successfully sent.
    func sendKeyEvent(_ params: SendKeyEventCommandParams, completion: @escaping NoResultHandler)
    
    /// Sends a mouse event.
    ///
    /// - Parameters:
    ///   - params: The mouse event parameters. See `SendMouseEventCommandParams`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the mouse event was successfully sent.
    func sendMouseEvent(_ params: SendMouseEventCommandParams, completion: @escaping NoResultHandler)
    
    /// Sends a gamepad event.
    ///
    /// - Parameters:
    ///   - params: The gamepad event parameters. See `SendGamepadEventCommandParams`.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the gamepad event was successfully sent.
    func sendGamepadEvent(_ params: SendGamepadEventCommandParams, completion: @escaping NoResultHandler)
}

/// Extension to send custom commands.
public protocol SenderDevice {
    
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
    ///   - message: The message to send.
    ///   - domain: The domain.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    func send<T: OCastMessage, U: Codable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping ResultHandler<U>)
}

/// Extension to manage default parameter values (forbidden in a protocol).
public extension Device {
    
    func disconnect(completion: NoResultHandler? = nil) {
        disconnect(completion: completion)
    }
    
    func prepareMedia(_ params: PrepareMediaCommandParams, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        prepareMedia(params, withOptions: options, completion: completion)
    }
}
