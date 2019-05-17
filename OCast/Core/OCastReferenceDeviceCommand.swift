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
//
//  OCastReferenceDeviceCommand.swift
//  OCast
//
//  Created by Christophe Azemar on 15/05/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

extension OCastDevice {
    
    // MARK: Media commands
    
    public func prepare(_ prepare: MediaPrepareCommand, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "prepare", params: prepare, options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func setTrack(_ track: MediaTrackCommand, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "track", params: track, options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func play(at position: Double, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "play", params: MediaPlayCommand(position: position), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func stop(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "stop", params: MediaStopCommand(), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func resume(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "resume", params: MediaResumeCommand(), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func setVolume(_ volume: Float, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "volume", params: MediaVolumeCommand(volume: volume), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func pause(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "pause", params: MediaPauseCommand(), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func seek(to position: Double, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "seek", params: MediaSeekCommand(position: position), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func metadata(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithResultHandler<MediaMetadataChanged>) {
        let command = OCastDataLayer(name: "getMetadata", params: MediaGetMetadataCommand(), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func playbackStatus(withOptions options: [String: Any]? = nil, completion: @escaping CommandWithResultHandler<MediaPlaybackStatus>) {
        let command = OCastDataLayer(name: "getPlaybackStatus", params: MediaGetPlaybackStatusCommand(), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func mute(_ flag: Bool, withOptions options: [String: Any]? = nil, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "mute", params: MediaMuteCommand(mute: flag), options: options)
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completion)
    }
    
    // MARK: Device settings commands
    
    public func updateStatus(_ completion: @escaping CommandWithResultHandler<SettingsUpdateStatus>) {
        let command = OCastDataLayer(name: "getUpdateStatus", params: SettingsGetUpdateStatusCommand())
        let message = OCastApplicationLayer(service: OCastDeviceSettingsServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func deviceID(_ completion: @escaping CommandWithResultHandler<SettingsDeviceID>) {
        let command = OCastDataLayer(name: "getDeviceID", params: SettingsGetDeviceIDCommand())
        let message = OCastApplicationLayer(service: OCastDeviceSettingsServiceName, data: command)
        send(message, completion: completion)
    }
    
    // MARK: Input settings commands
    
    public func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "keyPressed", params: keyEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "mouseEvent", params: mouseEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, completion: completion)
    }
    
    public func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping CommandWithoutResultHandler) {
        let command = OCastDataLayer(name: "gamepadEvent", params: gamepadEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, completion: completion)
    }
}
