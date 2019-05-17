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
public enum DeviceState: Int {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

@objc
public protocol OCastDeviceProtocol : OCastSSDPDevice, OCastDevicePublic {}

@objc
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
    var sslConfiguration: SSLConfiguration { set get }
        
    init(ipAddress: String, applicationURL: String)
        
    // Connection
    
    func connect(_ configuration: SSLConfiguration, completion: @escaping CommandWithoutResultHandler)
    func disconnect(_ completion: @escaping CommandWithoutResultHandler)
        
    // Application
    
    func startApplication(_ completion: @escaping CommandWithoutResultHandler)
    func stopApplication(_ completion: @escaping CommandWithoutResultHandler)
    
    // Events
    func registerEvent(_ name: String, withHandler handler: @escaping EventHandler)
    
    // Media commands
    
    func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func play(at position: Double, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func stop(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func resume(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func setVolume(_ volume: Float, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func pause(withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func seek(to position: Double, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    func metadata(withOptions options: [String: Any]?, completion: @escaping CommandWithResultHandler<MediaMetadataChanged>)
    func playbackStatus(withOptions options: [String: Any]?, completion: @escaping CommandWithResultHandler<MediaPlaybackStatus>)
    func mute(_ flag: Bool, withOptions options: [String: Any]?, completion: @escaping CommandWithoutResultHandler)
    
    // Settings commands
    
    func updateStatus(_ completion: @escaping CommandWithResultHandler<SettingsUpdateStatus>)
    func deviceID(_ completion: @escaping CommandWithResultHandler<SettingsDeviceID>)
    
    // Settings input commands
    
    func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping CommandWithoutResultHandler)
    func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping CommandWithoutResultHandler)
    func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping CommandWithoutResultHandler)
}

public protocol OCastSenderDevice {
    
    func send<T: OCastMessage>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping CommandWithoutResultHandler)
    func send<T: OCastMessage, U: Decodable>(_ message: OCastApplicationLayer<T>, on domain: OCastDomainName, completion: @escaping CommandWithResultHandler<U>)
}
