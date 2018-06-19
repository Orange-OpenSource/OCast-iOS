//
// MediaController.swift
//
// Copyright 2017 Orange
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

/// The delegate of a MediaController object must adopt the MediaControllerDelegate protocol in order to receive media events.
@objc public protocol MediaControllerDelegate {
    
    /// Tells the delegate that the mediaController has received a playback status event.
    ///
    /// - Parameters:
    ///   - mediaController: The `MediaController` instance.
    ///   - playbackStatus: The `PlaybackStatus`object containing playback information.
    func mediaController(_ mediaController: MediaController, didReceivePlaybackStatus playbackStatus: PlaybackStatus)

    /// Tells the delegate that the mediaController has received a metadata event.
    ///
    /// - Parameters:
    ///   - mediaController: The `MediaController` instance.
    ///   - metadata: The `Metadata`object containing metadata information.
    func mediaController(_ mediaController: MediaController, didReceiveMetadata metadata: Metadata)
}

/** Provides basic media control.

 ```
 mediaController = deviceManager.getMediaController()
 ```
 */
@objcMembers
public final class MediaController: NSObject, DataStream {
    private static let mediaControllerErrorDomainName = "MediaController"
    
    private let delegate: MediaControllerDelegate?
    
    internal init(with delegate: MediaControllerDelegate?) {
        self.delegate = delegate
    }

    // MARK: - Public interface

    /**
     Prepares a cast command
     - Parameters:
         - data: the data representing the media to be casted. See `MediaPrepare` class.
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func prepare(for data: MediaPrepare, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = [
            "url": data.url.absoluteString,
            "frequency": data.frequency,
            "title": data.title,
            "subtitle": data.subtitle,
            "logo": data.logo.absoluteString,
            "mediaType": data.mediaType.toString(),
            "transferMode": data.transferMode.toString(),
            "autoplay": data.autoplay,
        ]

        let dict: [String: Any] = ["name": "prepare", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Pauses the current media
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func pause(withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "pause", "params": [], "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }
    
    /**
     Stops the current media
     - Parameters:
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */
    public func stop(withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "stop", "params": [], "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Resumes the current media cast
     - Parameters:
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func resume(withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "resume", "params": [], "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Plays the current media from a given position
     - Parameters:
         - position: starting position (in seconds)
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func play(to position: UInt, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["position": position]
        let dict: [String: Any] = ["name": "play", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Sets the volume level
     - Parameters:
         - level: volume level in a [0..1] interval.
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func volume(to level: Float, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["volume": level]
        let dict: [String: Any] = ["name": "volume", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Seeks the current media to a given position
     - Parameters:
         - position: position
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func seek(to position: UInt, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["position": position]
        let dict: [String: Any] = ["name": "seek", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Sets a media track
     - Parameters:
         - type: track type (See `TrackType` for description)
         - id: track ID
         - enabled: `true` to enable the track, `false` to disable the track.
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func track(type: TrackType, id: String, enabled: Bool, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["type": type.toString(), "trackId": id, "enabled": enabled]
        let dict: [String: Any] = ["name": "track", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Mutes the current media
     - Parameters:
         - isMuted: `true` to mute the media, `false` to unmute the media.
         - onSuccess: the closure to be called in case of success.
         - onError: the closure to be called in case of error
     */
    public func mute(isMuted: Bool, withOptions options: [String: Any] = [:], onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["mute": isMuted]
        let dict: [String: Any] = ["name": "mute", "params": params, "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Gets current media metadata. See `MetaDataChanged` for details.
     - Parameters:
         - onSuccess: the closure to be called in case of success. Return the metadata description.
         - onError: the closure to be called in case of error
     */
    public func metadata(withOptions options: [String: Any] = [:], onSuccess: @escaping (_: Metadata) -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "getMetadata", "params": [], "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handleMetadataResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }

    /**
     Gets current media status. See `PlaybackStatus` for details.
     - Parameters:
         - onSuccess: the closure to be called in case of success. Return the media status description.
         - onError: the closure to be called in case of error
     */
    public func playbackStatus(withOptions options: [String: Any] = [:], onSuccess: @escaping (_: PlaybackStatus) -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "getPlaybackStatus", "params": [], "options": options]
        
        dataSender?.send(message: dict,
                         onSuccess: { response in
                            self.handlePlaybackStatusResponse(response, onSuccess: onSuccess, onError: onError)
        },
                         onError: onError)
    }
    
    // MARK: - Internal
    
    func code(from response: [String: Any]?) -> MediaErrorCode {
        guard let data = response,
            let streamData = DataMapper().streamData(with: data),
            let code = streamData.params["code"] as? Int,
            let errorCode = MediaErrorCode(rawValue: code) else {
                return MediaErrorCode.invalidErrorCode
        }
        return errorCode
    }
    
    func metadata(from response: [String: Any]?) -> Metadata? {
        guard let data = response,
            let streamData = DataMapper().streamData(with: data),
            let metaData = DataMapper().metadata(with: streamData) else { return nil }
        
        return metaData
    }
    
    func playbackStatus(from response: [String: Any]?) -> PlaybackStatus? {
        guard let data = response,
            let streamData = DataMapper().streamData(with: data),
            let playbackStatus = DataMapper().playbackStatus(with: streamData) else { return nil }
        
        return playbackStatus
    }
    
    private func error(from errorCode: MediaErrorCode) -> NSError {
        return NSError(domain: MediaController.mediaControllerErrorDomainName, code: errorCode.rawValue)
    }
    
    private func handleResponse(_ response: [String: Any]?, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let errorCode = code(from: response)
        
        if errorCode == MediaErrorCode.noError {
            onSuccess()
        } else {
            onError(error(from: errorCode))
        }
    }
    
    private func handleMetadataResponse(_ response: [String: Any]?, onSuccess: @escaping (_: Metadata) -> Void, onError: @escaping (NSError?) -> Void) {
        let errorCode = code(from: response)
        
        if errorCode == MediaErrorCode.noError {
            if let metaData = metadata(from: response) {
                onSuccess(metaData)
            } else {
                onError(NSError(domain: MediaController.mediaControllerErrorDomainName, code: MediaErrorCode.invalidMetadata.rawValue))
            }
        } else {
            onError(error(from: errorCode))
        }
    }
    
    private func handlePlaybackStatusResponse(_ response: [String: Any]?, onSuccess: @escaping (_: PlaybackStatus) -> Void, onError: @escaping (NSError?) -> Void) {
        let errorCode = code(from: response)
        
        if errorCode == MediaErrorCode.noError {
            if let playbackStatus = playbackStatus(from: response) {
                onSuccess(playbackStatus)
            } else {
                onError(NSError(domain: MediaController.mediaControllerErrorDomainName, code: MediaErrorCode.invalidPlaybackStatus.rawValue))
            }
        } else {
            onError(error(from: errorCode))
        }
    }

    // MARK: - DataStream implementation

    /// :nodoc:
    public var dataSender: DataSender?
    
    /// :nodoc:
    public let serviceId = "org.ocast.media"
    
    /// :nodoc:
    public func onMessage(data: [String: Any]) {
        guard let streamData = DataMapper().streamData(with: data) else {
            OCastLog.debug("Receive a bad formatted message")
            return
        }

        switch streamData.name {
            case "playbackStatus":
                if let playbackStatus = DataMapper().playbackStatus(with: streamData) {
                    delegate?.mediaController(self, didReceivePlaybackStatus: playbackStatus)
                }
            case "metadataChanged":
                if let metaData = DataMapper().metadata(with: streamData) {
                    delegate?.mediaController(self, didReceiveMetadata: metaData)
                }
            default:
                return
        }
    }
}
