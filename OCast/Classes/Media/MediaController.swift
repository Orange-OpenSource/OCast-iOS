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
/**
 Provides information on media.
 */

@objc public protocol MediaControllerProtocol {
    /**
     Gets called when a media status has been received from the web application
     - Parameter data: data with the status information. See `PlaybackStatus` for details.
     */
    func onPlaybackStatus(data: PlaybackStatus)

    /**
     Gets called when the media metadata changed.
     - Parameter data: data with the metadata information. See `MetaDataChanged` for details.
     */
    func onMetaDataChanged(data: MetaDataChanged)
}

/** Provides basic media control.

 ```
 mediaController = deviceManager.getMediaController()
 ```
 */

public final class MediaController: NSObject, DataStreamable {

    // MARK: - Public interface

    /**
     Prepares a cast command
     - Parameters:
     - data: the data representing the media to be casted. See `MediaPrepare` class.
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func prepare(for data: MediaPrepare, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {

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

        let dict: [String: Any] = ["name": "prepare", "params": params, "options": []]

        sendMessage(with: dict,
                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Pauses the current media
     - Parameters:
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func pause(onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "pause", "params": [], "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Stops the current media
     - Parameters:
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func stop(onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "stop", "params": [], "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Resumes the current media cast
     - Parameters:
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func resume(onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "resume", "params": [], "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Plays the current media from a given position
     - Parameters:
     - position: starting position (in seconds)
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func play(to position: UInt, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["position": position]
        let dict: [String: Any] = ["name": "play", "params": params, "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Sets the vomume level
     - Parameters:
     - volume: volume level in a [0..1] interval.
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func volume(to level: Float, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["level": level]
        let dict: [String: Any] = ["name": "volume", "params": params, "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Seeks the current media to a given position
     - Parameters:
     - position: position
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func seek(to position: UInt, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["position": position]
        let dict: [String: Any] = ["name": "seek", "params": params, "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
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

    public func track(type: TrackType, id: String, enabled: Bool, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["type": type.toString(), "trackId": id, "enabled": enabled]

        let dict: [String: Any] = ["name": "track", "params": params, "options": []]

        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Mutes the current media
     - Parameters:
     - isMuted: `true` to mute the media, `false` to unmute the media.
     - onSuccess: the closure to be called in case of success.
     - onError: the closure to be called in case of error
     */

    public func mute(isMuted: Bool, onSuccess: @escaping () -> Void, onError: @escaping (NSError?) -> Void) {
        let params: [String: Any] = ["mute": isMuted]
        let dict: [String: Any] = ["name": "mute", "params": params, "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode == MediaErrorCode.noError {
                            onSuccess()
                            return
                        }

                        let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                        onError(newError)
                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Gets current media metadata. See `MetaDataChanged` for details.
     - Parameters:
     - onSuccess: the closure to be called in case of success. Return the metadata description.
     - onError: the closure to be called in case of error
     */

    public func getMetadata(onSuccess: @escaping (_: MetaDataChanged) -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "getMetadata", "params": [], "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode != MediaErrorCode.noError {
                            let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                            onError(newError)
                            return
                        }

                        guard let metaData = self.getMetaData(from: response) else {
                            return
                        }

                        onSuccess(metaData)

                    },

                    onError: { error in onError(error) }
        )
    }

    /**
     Gets current media status. See `PlaybackStatus` for details.
     - Parameters:
     - onSuccess: the closure to be called in case of success. Return the media status description.
     - onError: the closure to be called in case of error
     */

    public func getPlaybackStatus(onSuccess: @escaping (_: PlaybackStatus) -> Void, onError: @escaping (NSError?) -> Void) {
        let dict: [String: Any] = ["name": "getPlaybackStatus", "params": [], "options": []]
        sendMessage(with: dict,

                    onSuccess: { response in

                        guard let errorCode = self.getCode(from: response) else {
                            return
                        }

                        if errorCode != MediaErrorCode.noError {
                            let newError = NSError(domain: "MediaController", code: errorCode.rawValue, userInfo: ["MediaError": errorCode.toString()])
                            onError(newError)
                            return
                        }

                        guard let metaData = self.getPlaybackInfo(from: response) else {
                            return
                        }

                        onSuccess(metaData)

                    },

                    onError: { error in onError(error) }
        )
    }

    // MARK: - DataStreamable Protocol

    /// :nodoc:
    public var messageSender: MessagerSender?

    /// :nodoc:
    public let serviceId = "org.ocast.media"

    /// :nodoc:
    public func onMessage(data: [String: Any]) {

        guard let mediaData = DataMapper().getMediaControllerData(data: data) else {
            return
        }

        switch mediaData.name {

        case "playbackStatus":
            let playbackStatus = DataMapper().getPlaybackStatus(with: mediaData)
            sender.onPlaybackStatus(data: playbackStatus)

        case "metadataChanged":
            guard let metaData = DataMapper().getMetaData(from: mediaData) else {
                return
            }

            sender.onMetaDataChanged(data: metaData)

        default:
            return
        }
    }

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Internal

    let sender: MediaControllerProtocol
    var commandId: Int = 0

    init(from sender: Any) {
        self.sender = sender as! MediaControllerProtocol
    }

    func getCode(from response: [String: Any]?) -> MediaErrorCode? {

        guard let response = response else {
            return nil
        }

        guard let data = response["data"] as? [String: Any] else {
            return nil
        }

        guard let mediaData = DataMapper().getMediaControllerData(data: data) else {
            return nil
        }

        guard let code = mediaData.params["code"] else {
            return nil
        }

        if let codeAsInt = code as? Int {

            guard let errorCode = MediaErrorCode(rawValue: codeAsInt) else {
                return nil
            }

            return errorCode
        }

        return nil
    }

    func getMetaData(from response: [String: Any]?) -> MetaDataChanged? {

        guard let response = response else {
            return nil
        }

        guard let data = response["data"] as? [String: Any] else {
            return nil
        }

        guard let mediaData = DataMapper().getMediaControllerData(data: data) else {
            return nil
        }

        guard let metaData = DataMapper().getMetaData(from: mediaData) else {
            return nil
        }

        return metaData
    }

    func getPlaybackInfo(from response: [String: Any]?) -> PlaybackStatus? {

        guard let response = response else {
            return nil
        }

        guard let data = response["data"] as? [String: Any] else {
            return nil
        }

        guard let mediaData = DataMapper().getMediaControllerData(data: data) else {
            return nil
        }

        let playbackInfo = DataMapper().getPlaybackStatus(with: mediaData)
        return playbackInfo
    }
}
