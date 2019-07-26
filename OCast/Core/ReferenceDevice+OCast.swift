//
// ReferenceDevice+OCast.swift
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

/// Extension to manage messages described by the OCast specification.
extension ReferenceDevice {
    
    // MARK: - Media methods
    
    /// Sends a media message without result.
    ///
    /// - Parameters:
    ///   - data: The data to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent.
    private func sendMediaMessage<T: OCastMessage>(from data: OCastDataLayer<T>, completion: @escaping NoResultHandler) {
        let completionBlock: ResultHandler<NoResult> = { _, error in
            completion(error)
        }
        sendMediaMessage(from: data, completion: completionBlock)
    }
    
    /// Sends a media message with a result.
    ///
    /// - Parameters:
    ///   - data: The data to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    private func sendMediaMessage<T: OCastMessage, U: Codable>(from data: OCastDataLayer<T>, completion: @escaping ResultHandler<U>) {
        let completionBlock: ResultHandler<U> = { result, error in
            if let error = error as? OCastReplyError {
                completion(result, MediaError(rawValue: error.code) ?? .unknownError)
            } else {
                completion(result, error)
            }
        }
        let message = OCastApplicationLayer(service: OCastMediaServiceName, data: data)
        send(message, completion: completionBlock)
    }
    
    public func prepareMedia(_ params: PrepareMediaCommandParams, withOptions options: [String: Any]?, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "prepare", params: params, options: options)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func setMediaTrack(_ params: SetMediaTrackCommandParams, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "track", params: params, options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func playMedia(at position: Double, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "play", params: PlayMediaCommandParams(position: position), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func stopMedia(completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "stop", params: StopMediaCommandParams(), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func resumeMedia(completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "resume", params: ResumeMediaCommandParams(), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func setMediaVolume(_ volume: Double, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "volume", params: SetMediaVolumeCommandParams(volume: volume), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func pauseMedia(completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "pause", params: PauseMediaCommandParams(), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func seekMedia(to position: Double, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "seek", params: SeekMediaCommandParams(position: position), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func mediaMetadata(completion: @escaping ResultHandler<MediaMetadata>) {
        let data = OCastDataLayer(name: "getMetadata", params: MediaMetadataCommandParams(), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func mediaPlaybackStatus(completion: @escaping ResultHandler<MediaPlaybackStatus>) {
        let data = OCastDataLayer(name: "getPlaybackStatus", params: MediaPlaybackStatusCommandParams(), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    public func muteMedia(_ flag: Bool, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "mute", params: MuteMediaCommandParams(muted: flag), options: nil)
        sendMediaMessage(from: data, completion: completion)
    }
    
    // MARK: - Device settings methods
    
    /// Sends a device settings message with a result.
    ///
    /// - Parameters:
    ///   - data: The data to send.
    ///   - completion: The completion block called when the action completes.
    /// If the error is nil, the message was successfully sent and is described in `U` parameter.
    private func sendDeviceSettingsMessage<T: OCastMessage, U: Codable>(from data: OCastDataLayer<T>, completion: @escaping ResultHandler<U>) {
        let completionBlock: ResultHandler<U> = { result, error in
            if let error = error as? OCastReplyError {
                completion(result, DeviceSettingsError(rawValue: error.code) ?? .unknownError)
            } else {
                completion(result, error)
            }
        }
        let message = OCastApplicationLayer(service: OCastDeviceSettingsServiceName, data: data)
        send(message, on: OCastDomainName.settings, completion: completionBlock)
    }
    
    public func updateStatus(completion: @escaping ResultHandler<UpdateStatus>) {
        let data = OCastDataLayer(name: "getUpdateStatus", params: UpdateStatusCommandParams())
        sendDeviceSettingsMessage(from: data, completion: completion)
    }
    
    public func deviceID(completion: @escaping ResultHandler<String>) {
        let data = OCastDataLayer(name: "getDeviceID", params: DeviceIDCommandParams())
        let completionBlock: ResultHandler<DeviceID> = { result, error in
            completion(result?.id, error)
        }
        sendDeviceSettingsMessage(from: data, completion: completionBlock)
    }
    
    // MARK: - Input settings methods
    
    public func sendKeyEvent(_ params: SendKeyEventCommandParams, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "keyPressed", params: params)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: data)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
    
    public func sendMouseEvent(_ params: SendMouseEventCommandParams, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "mouseEvent", params: params)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: data)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
    
    public func sendGamepadEvent(_ params: SendGamepadEventCommandParams, completion: @escaping NoResultHandler) {
        let data = OCastDataLayer(name: "gamepadEvent", params: params)
        let message = OCastApplicationLayer(service: OCastInputSettingsServiceName, data: data)
        send(message, on: OCastDomainName.settings, completion: completion)
    }
}
