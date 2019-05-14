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
    @objc
    public func prepare(_ command: MediaPrepareCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "prepare", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func track(_ command: MediaTrackCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "track", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func play(_ command: MediaPlayCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "play", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func stop(withOptions options: [String: Any]?, andCompletion handler : @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "stop", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaStopCommand(), andOptions: nil, andCompletion: handler)
    }
    
    public func resume(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "resume", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaResumeCommand(), andOptions: nil, andCompletion: handler)
    }
    
    public func volume(_ command: MediaVolumeCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "volume", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func pause(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "pause", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaPauseCommand(), andOptions: nil, andCompletion: handler)
    }
    
    public func seek(_ command: MediaSeekCommand, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "seek", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func metadata(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithResultHandler<MediaMetadataChanged>) {
        sendCustomCommand(name: "getMetadata", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaGetMetadataCommand(), andOptions: options, andCompletion: handler)
    }
    
    public func playbackStatus(withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithResultHandler<MediaPlaybackStatus>) {
        sendCustomCommand(name: "getPlaybackStatus", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaGetPlaybackStatusCommand(), andOptions: options, andCompletion: handler)
    }
    
    public func mute(_ isMuted: Bool, withOptions options: [String: Any]?, andCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "mute", forDomain: OCastDomainName.browser, andService: "org.ocast.media", withParams: MediaMuteCommand(mute: isMuted), andOptions: nil, andCompletion: handler)
    }
    
    // MARK: Settings commands
    public func updateStatusWithCompletionHandler(_ handler: @escaping CommandWithResultHandler<SettingsUpdateStatus>) {
        sendCustomCommand(name: "getUpdateStatus", forDomain: OCastDomainName.settings, andService: "org.ocast.settings.device", withParams: SettingsGetUpdateStatusCommand(), andOptions: nil, andCompletion: handler)
    }
    
    public func deviceIDWithCompletionHandler(_ handler: @escaping CommandWithResultHandler<SettingsDeviceID>) {
        sendCustomCommand(name: "getDeviceID", forDomain: OCastDomainName.settings, andService: "org.ocast.settings.device", withParams: SettingsGetDeviceIDCommand(), andOptions: nil, andCompletion: handler)
    }
    
    // MARK: Settings input commands
    public func keyPressed(_ command: SettingsKeyPressedCommand, withCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "keyPressed", forDomain: OCastDomainName.settings, andService: "org.ocast.settings.input", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func mouseEvent(_ command: SettingsMouseEventCommand, withCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "mouseEvent", forDomain: OCastDomainName.settings, andService: "org.ocast.settings.input", withParams: command, andOptions: nil, andCompletion: handler)
    }
    
    public func gamepadEvent(_ command: SettingsGamepadEventCommand, withCompletion handler: @escaping CommandWithoutResultHandler) {
        sendCustomCommand(name: "gamepadEvent", forDomain: OCastDomainName.settings, andService: "org.ocast.settings.input", withParams: command, andOptions: nil, andCompletion: handler)
    }
}
