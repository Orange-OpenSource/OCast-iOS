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
//  OCastDomainMedia.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation
import DynamicCodable

// MARK: - Media objects

/**
 Media type
 - `.audio`: audio type
 - `.image`: image type
 - `.video`: viedo type
 */
@objc public enum OCastMediaType: Int {
    case audio
    case image
    case video
}

extension OCastMediaType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .image: return "image"
        case .video: return"video"
        }
    }
    
    init(type : String) {
        switch (type) {
        case "audio": self = .audio
        case "video": self = .video
        case "image": self = .image
        default: self = .audio
        }
    }
}

@objc public enum OCastMediaTrackType: Int {
    case audio = 0
    case text
    case video
    case undefined
}

extension OCastMediaTrackType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .video: return "video"
        case .text: return "text"
        case .undefined: return "undefined"
        }
    }
}

/**
 Transfer mode
 - `.buffered`: buffered type
 - `.streamed`: streamed type
 */

@objc public enum OCastMediaTransferMode: Int {
    case buffered
    case streamed
}

extension OCastMediaTransferMode {
    func toString() -> String {
        switch self {
        case .buffered: return "buffered"
        case .streamed: return "streamed"
        }
    }
}

@objc
public enum MediaPlaybackStatusState: Int, Codable {
    case unknown, idle, playing, paused, buffering
    
    public func toString() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .idle :
            return "idle"
        case .playing:
            return "playing"
        case .paused:
            return "paused"
        case .buffering:
            return "buffering"
        }
    }
}

@objc
@objcMembers
public class MediaPlaybackStatus: OCastMessage {
    public var volume: Float { return _volume ?? 0.0 }
    public var mute: Bool { return _mute ?? false }
    public var state: MediaPlaybackStatusState { return _state ?? .unknown }
    public var position: Double { return _position ?? 0.0 }
    public var duration: Double { return _duration ?? 0.0 }
    
    private let _volume: Float?
    private let _mute: Bool?
    private let _state: MediaPlaybackStatusState?
    private let _position: Double?
    private let _duration: Double?
    
    enum CodingKeys : String, CodingKey {
        case _volume = "volume", _mute = "mute", _state = "state", _position = "position", _duration = "duration"
    }
    
}

@objc
public class MediaMetadataChanged: OCastMessage {
    public let title: String
    public let subtitle: String
    public let logo: String
    public let mediaType: OCastMediaType { return OCastMediaType(type: _mediaType) }
    private let _mediaType: String
    public let textTracks: [MediaTrack]
    public let audioTracks: [MediaTrack]
    public let videoTracks: [MediaTrack]
    
    enum CodingKeys : String, CodingKey {
        case title = "title", subtitle = "subtitle", logo = "logo", _mediaType = "mediaType", textTracks = "textTracks", audioTracks = "audioTracks", videoTracks = "videoTracks"
}

@objc
public class MediaTrack: OCastMessage {
    public let language: String
    public let enable: Bool
    public let trackId: String
}

// MARK: - Media Error Codes

/*
 Media controller error codes
 - `.noError`: No error
 - `.invalidService`: the service is not implemented by the web application
 - `.noImplementation`: the command is not yet implemented by the web application
 - `.missingParameter`: a mandatory parameter is missing
 - `.invalidPlayerState`: the command could not be performed according to the player state
 - `.playerNotReady`: the player could not be initialized
 - `.invalidTrack`: the track ID is not valid
 - `.unknowMediaType`: unknown media type
 - `.unknownTransferMode`: unknown transfer mode
 - `.unknownError`: Internal error
 */

@objc public enum OCastMediaErrorCode: Int {
    case noError = 0
    case invalidService = 2404
    case noImplementation = 2400
    case missingParameter = 2422
    case invalidPlayerState = 2412
    case playerNotReady = 2413
    case invalidTrack = 2414
    case unknowMediaType = 2415
    case unknownTransferMode = 2416
    case unknownError = 2500
    /// :nodoc:
    case invalidMetadata = 9997
    case invalidPlaybackStatus = 9998
    case invalidErrorCode = 9999
}

extension OCastMediaErrorCode {
    func toString() -> String {
        switch self {
        case .invalidService: return "invalidService"
        case .noImplementation: return "noImplementation"
        case .missingParameter: return "missingParameter"
        case .invalidPlayerState: return "invalidPlayerState"
        case .unknowMediaType: return "unknowMediaType"
        case .unknownTransferMode: return "unknownTransferMode"
        case .unknownError: return "unknownError"
        case .invalidTrack: return "invalidTtrack"
        case .noError: return"noError"
        default: return "Unvalid error code"
        }
    }
}

// MARK: - Media Commands
@objc
public class MediaPrepareCommand: OCastMessage {
    public let url: String
    public let frequency: UInt
    public let title: String
    public let subtitle: String
    public let logo: String
    public let mediaType: String
    public let transferMode: String
    public let autoplay: Bool
    
    @objc
    public init(url: String, frequency: UInt, title: String, subtitle: String, logo: String, mediaType: OCastMediaType, transferMode: OCastMediaTransferMode, autoPlay: Bool) {
        self.url = url
        self.frequency = frequency
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self.mediaType = mediaType.toString()
        self.transferMode = transferMode.toString()
        self.autoplay = autoPlay
    }
}

@objc
public class MediaTrackCommand: OCastMessage {
    public let type: String
    public let trackId: String
    public let enable: Bool
    
    public init(type: String, trackId: String, enable: Bool) {
        self.type = type
        self.trackId = trackId
        self.enable = enable
    }
}

@objc
public class MediaPlayCommand: OCastMessage {
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

@objc public class MediaStopCommand: OCastMessage {}
@objc public class MediaResumeCommand: OCastMessage {}

@objc public class MediaVolumeCommand: OCastMessage {
    public let volume: Float
    
    public init(volume: Float) {
        self.volume = volume
    }
}

@objc
public class MediaPauseCommand: OCastMessage {}

@objc
public class MediaSeekCommand: OCastMessage {
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

@objc public class MediaGetPlaybackStatusCommand: OCastMessage {}
@objc public class MediaGetDeviceIDCommand: OCastMessage {}
@objc public class MediaGetMetadataCommand: OCastMessage {}

@objc
public class MediaMuteCommand: OCastMessage {
    public let mute: Bool
    
    public init(mute: Bool) {
        self.mute = mute
    }
}
