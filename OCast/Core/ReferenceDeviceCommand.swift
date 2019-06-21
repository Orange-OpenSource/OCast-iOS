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
//  ReferenceDeviceCommand.swift
//  OCast
//
//  Created by Christophe Azemar on 15/05/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

/// Manage the commands described by the OCast specification.
extension ReferenceDevice {
    
    // MARK: - Media commands methods
    
    /// Sends a media command without result.
    ///
    /// - Parameters:
    ///   - command: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent.
    private func sendMediaCommand<T: OCastMessage>(_ command: OCastDataLayer<T>, completion: @escaping NoResultHandler) {
        let completionBlock: ResultHandler<NoResult> = { _, error in
            completion(error)
        }
        sendMediaCommand(command, completion: completionBlock)
    }
    
    /// Sends a media command with a result.
    ///
    /// - Parameters:
    ///   - command: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent and is described in `U` parameter.
    private func sendMediaCommand<T: OCastMessage, U: Codable>(_ command: OCastDataLayer<T>, completion: @escaping ResultHandler<U>) {
        let completionBlock: ResultHandler<U> = { result, error in
            if let error = error as? OCastReplyError {
                completion(result, MediaError(rawValue: error.code) ?? .unknownError)
            } else {
                completion(result, error)
            }
        }
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: command)
        send(message, completion: completionBlock)
    }
    
    public func prepare(_ prepareCommand: MediaPrepareCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "prepare", params: prepareCommand, options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func setTrack(_ trackCommand: MediaTrackCommand, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "track", params: trackCommand, options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func play(at position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "play", params: MediaPlayCommand(position: position), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func stop(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "stop", params: MediaStopCommand(), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func resume(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "resume", params: MediaResumeCommand(), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func setVolume(_ volume: Float, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "volume", params: MediaVolumeCommand(volume: volume), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func pause(withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "pause", params: MediaPauseCommand(), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func seek(to position: Double, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "seek", params: MediaSeekCommand(position: position), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func metadata(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaMetadata>) {
        let command = OCastDataLayer(name: "getMetadata", params: MediaGetMetadataCommand(), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func playbackStatus(withOptions options: [String: Any]? = nil, completion: @escaping ResultHandler<MediaPlaybackStatus>) {
        let command = OCastDataLayer(name: "getPlaybackStatus", params: MediaGetPlaybackStatusCommand(), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    public func mute(_ flag: Bool, withOptions options: [String: Any]? = nil, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "mute", params: MediaMuteCommand(mute: flag), options: options)
        sendMediaCommand(command, completion: completion)
    }
    
    // MARK: - Device settings commands
    
    /// Sends a device settings command with a result.
    ///
    /// - Parameters:
    ///   - command: The command to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the command was successfully sent and is described in `U` parameter.
    private func sendDeviceSettingsCommand<T: OCastMessage, U: Codable>(_ command: OCastDataLayer<T>, completion: @escaping ResultHandler<U>) {
        let completionBlock: ResultHandler<U> = { result, error in
            if let error = error as? OCastReplyError {
                completion(result, OCastDeviceSettingsError(rawValue: error.code) ?? .unknownError)
            } else {
                completion(result, error)
            }
        }
        let message = OCastApplicationLayer(service: OCastDeviceSettingsServiceName, data: command)
        send(message, on: OCastDomainName.settings, completion: completionBlock)
    }
    
    public func updateStatus(_ completion: @escaping ResultHandler<SettingsUpdateStatus>) {
        let command = OCastDataLayer(name: "getUpdateStatus", params: SettingsGetUpdateStatusCommand())
        sendDeviceSettingsCommand(command, completion: completion)
    }
    
    public func deviceID(_ completion: @escaping ResultHandler<String>) {
        let command = OCastDataLayer(name: "getDeviceID", params: SettingsGetDeviceIDCommand())
        let completionBlock: ResultHandler<SettingsDeviceID> = { result, error in
            completion(result?.id, error)
        }
        sendDeviceSettingsCommand(command, completion: completionBlock)
    }
    
    // MARK: - Input settings commands
    
    public func sendKeyEvent(_ keyEvent: SettingsKeyPressedCommand, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "keyPressed", params: keyEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
    
    public func sendMouseEvent(_ mouseEvent: SettingsMouseEventCommand, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "mouseEvent", params: mouseEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
    
    public func sendGamepadEvent(_ gamepadEvent: SettingsGamepadEventCommand, completion: @escaping NoResultHandler) {
        let command = OCastDataLayer(name: "gamepadEvent", params: gamepadEvent)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: command)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
}