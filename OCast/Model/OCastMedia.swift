//
// OCastMedia.swift
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

/// The media service name
public let OCastMediaServiceName = "org.ocast.media"

// MARK: - Media objects

/// The media type.
///
/// - audio: Audio type.
/// - image: Image type.
/// - video: Video type.
@objc
public enum MediaType: Int, RawRepresentable, Codable {
    case audio, image, video
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .audio: return "audio"
        case .image: return "image"
        case .video: return"video"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "audio": self = .audio
        case "video": self = .video
        case "image": self = .image
        default: return nil
        }
    }
}

/// The media track type.
///
/// - audio: Audio track.
/// - subtitle: Subtitle track.
/// - video: Video track.
@objc
public enum MediaTrackType: Int, RawRepresentable, Codable {
    
    case audio = 0, subtitle, video, undefined
    
    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .audio: return "audio"
        case .video: return "video"
        case .subtitle: return "text"
        case .undefined: return "undefined"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "audio": self = .audio
        case "video": self = .video
        case "text": self = .subtitle
        default: return nil
        }
    }
}

/// The media transfer mode.
///
/// - buffered: Buffered (VOD, replay).
/// - streamed: Streamed (Live streaming).
@objc
public enum MediaTransferMode: Int, RawRepresentable, Codable {
    
    case buffered, streamed
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .buffered: return "buffered"
        case .streamed: return "streamed"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "buffered": self = .buffered
        case "streamed": self = .streamed
        default: return nil
        }
    }
}

/// The media playback state.
///
/// - idle: No media is running.
/// - buffering: A media is buffering.
/// - playing: A media is playing.
/// - paused: A media is paused.
@objc
public enum MediaPlaybackState: Int, Codable {
    
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

/// The media playback status.
@objc
@objcMembers
public class MediaPlaybackStatus: OCastMessage {
    
    private let _volume: Float?
    private let _mute: Bool?
    private let _position: Double?
    private let _duration: Double?
    
    /// The volume level between 0 and 1.
    public var volume: Float { return _volume ?? 0.0 }
    
    /// `true` if the media is muted, otherwise `false`.
    public var muted: Bool { return _mute ?? false }
    
    /// The media state.
    public let state: MediaPlaybackState
    
    // The media position in seconds.
    public var position: Double { return _position ?? 0.0 }
    
    /// The media duration in seconds.
    public var duration: Double { return _duration ?? 0.0 }
    
    enum CodingKeys: String, CodingKey {
        case _volume = "volume", _mute = "mute", state = "state", _position = "position", _duration = "duration"
    }
}

/// The media metadata.
@objc
@objcMembers
public class MediaMetadata: OCastMessage {
    
    private let _mediaType: String
    
    /// The title.
    public let title: String
    
    /// The subtitle.
    public let subtitle: String
    
    /// The logo.
    public let logo: String
    
    /// The media type. See `MediaType`.
    public var mediaType: MediaType { return MediaType(rawValue: _mediaType) ?? .audio }
    
    /// The subtitle tracks. See `MediaTrack`.
    public let subtitleTracks: [MediaTrack]
    
    /// The audio tracks. See `MediaTrack`.
    public let audioTracks: [MediaTrack]
    
    /// The video tracks. See `MediaTrack`.
    public let videoTracks: [MediaTrack]
    
    public init(title: String, subtitle: String, logo: String, mediaType: MediaType, subtitleTracks: [MediaTrack], audioTracks: [MediaTrack], videoTracks: [MediaTrack]) {
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self._mediaType = mediaType.rawValue
        self.subtitleTracks = subtitleTracks
        self.audioTracks = audioTracks
        self.videoTracks = videoTracks
    }
    
    enum CodingKeys: String, CodingKey {
        case title = "title", subtitle = "subtitle", logo = "logo", _mediaType = "mediaType", subtitleTracks = "textTracks", audioTracks = "audioTracks", videoTracks = "videoTracks"
    }
}

/// The media track.
@objc
@objcMembers
public class MediaTrack: OCastMessage {
    
    /// The track identifier.
    public let trackId: String
    
    /// The ISO639-1/2 language.
    public let language: String
    
    /// The name.
    public let label: String
    
    /// `true` if the track is enabled, otherwise `false`.
    public let enabled: Bool
    
    public init(trackId: String, language: String, label: String, enabled: Bool) {
        self.trackId = trackId
        self.language = language
        self.label = label
        self.enabled = enabled
    }
}

// MARK: - Media error codes

/// The media errors.
///
/// - invalidService: The service is not implemented by the web application.
/// - noImplementation: The command is not yet implemented by the web application.
/// - missingParameter: A mandatory parameter is missing.
/// - invalidPlayerState: The command could not be performed according to the player state.
/// - playerNotReady: The player could not be initialized.
/// - invalidTrack: The track identifier is not valid.
/// - unknowMediaType: The media type is unknown.
/// - unknownTransferMode: The media transfer mode is unknown.
/// - internalError: An internal error occurs.
/// - unknownError: An unknown error occurs.
@objc public enum MediaError: Int, Error {
    case invalidService = 2404
    case noImplementation = 2400
    case missingParameter = 2422
    case invalidPlayerState = 2412
    case playerNotReady = 2413
    case invalidTrack = 2414
    case unknowMediaType = 2415
    case unknownTransferMode = 2416
    case internalError = 2500
    case unknownError = 2999
}

// MARK: - Media parameters

/// The parameters to prepare a media.
@objc
@objcMembers
public class PrepareMediaCommandParams: OCastMessage {
    
    //// The media URL to launch.
    public let url: String
    
    /// The frequency to receive playback status events.
    public let frequency: UInt
    
    /// The media title.
    public let title: String
    
    /// The media subtitle.
    public let subtitle: String
    
    /// The media logo.
    public let logo: String
    
    /// The media type. See `MediaType`.
    public let mediaType: MediaType
    
    /// The media transfer mode. See `MediaTransferMode`.
    public let transferMode: MediaTransferMode
    
    /// `true` if the media must be lauched automatically, othewise `false`.
    public let autoplay: Bool
    
    public init(url: String, frequency: UInt, title: String, subtitle: String, logo: String, mediaType: MediaType, transferMode: MediaTransferMode, autoPlay: Bool) {
        self.url = url
        self.frequency = frequency
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self.mediaType = mediaType
        self.transferMode = transferMode
        self.autoplay = autoPlay
    }
}

/// The parameters to set a media track.
@objc
@objcMembers
public class SetMediaTrackCommandParams: OCastMessage {
    
    /// The track identifier.
    public let trackId: String

    /// The media track type. See `MediaTrackType`.
    public let type: MediaTrackType
    
    /// `true` to enable the track, `false` to disable it.
    public let enabled: Bool
    
    public init(trackId: String, type: MediaTrackType, enabled: Bool) {
        self.type = type
        self.trackId = trackId
        self.enabled = enabled
    }
    
    enum CodingKeys: String, CodingKey {
        case trackId, type, enabled = "enable"
    }
}

/// The parameters to play a media.
@objc
@objcMembers
public class PlayMediaCommandParams: OCastMessage {
    
    /// The position in seconds.
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

/// The parameters to stop a media.
@objc
@objcMembers
public class StopMediaCommandParams: OCastMessage {}

/// The parameters to resume a media.
@objc
@objcMembers
public class ResumeMediaCommandParams: OCastMessage {}

/// The parameters to set the volume of a media.
@objc
@objcMembers
public class SetMediaVolumeCommandParams: OCastMessage {
    
    // The volume level between 0 and 1.
    public let volume: Double
    
    public init(volume: Double) {
        self.volume = volume
    }
}

/// The parameters to pause a media.
@objc
@objcMembers
public class PauseMediaCommandParams: OCastMessage {}

/// The parameters to seek a media.
@objc
@objcMembers
public class SeekMediaCommandParams: OCastMessage {
    
    // The position which to seek in seconds.
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

/// The parameters to retrieve the media playback status.
@objc
@objcMembers
public class MediaPlaybackStatusCommandParams: OCastMessage {}

/// The parameters to retrieve the media metadata.
@objc
@objcMembers
public class MediaMetadataCommandParams: OCastMessage {}

/// The parameters to mute a media.
@objc
@objcMembers
public class MuteMediaCommandParams: OCastMessage {
    
    /// `true`to mute the media, `false` to unmute it.
    public let muted: Bool
    
    public init(muted: Bool) {
        self.muted = muted
    }
    
    enum CodingKeys: String, CodingKey {
        case muted = "mute"
    }
}
