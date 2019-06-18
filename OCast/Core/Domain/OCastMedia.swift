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
//  OCastMedia.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

/// The media service name
public let OCastMediaServiceName = "org.ocast.media"

/// The notification sent when a playback status event is received.
/// The userinfo `PlaybackStatusUserInfoKey` key contains playback status information.
public let PlaybackStatusEventNotification = Notification.Name("PlaybackStatusEvent")

/// The notification sent when a metadata event is received.
/// The userinfo `MetadataUserInfoKey` key contains metadata information.
public let MetadataChangedEventNotification = Notification.Name("MetadataChangedEvent")

/// The notification user info key representing the playback status.
public let PlaybackStatusUserInfoKey = Notification.Name("PlaybackStatusKey")

/// The notification user info key representing the metadata.
public let MetadataUserInfoKey = Notification.Name("MetadataKey")

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
        switch (rawValue) {
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
        switch (rawValue) {
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
        switch (rawValue) {
        case "buffered": self = .buffered
        case "streamed": self = .streamed
        default: return nil
        }
    }
}

/// The media playback status state.
///
/// - idle: No media is running.
/// - buffering: A media is buffering.
/// - playing: A media is playing.
/// - paused: A media is paused.
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
    public var mute: Bool { return _mute ?? false }
    
    /// The media state.
    public let state: MediaPlaybackStatusState
    
    // The media position in seconds.
    public var position: Double { return _position ?? 0.0 }
    
    /// The media duration in seconds.
    public var duration: Double { return _duration ?? 0.0 }
    
    enum CodingKeys : String, CodingKey {
        case _volume = "volume", _mute = "mute", state = "state", _position = "position", _duration = "duration"
    }
}

/// The media metadata.
@objc
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
    
    enum CodingKeys : String, CodingKey {
        case title = "title", subtitle = "subtitle", logo = "logo", _mediaType = "mediaType", subtitleTracks = "textTracks", audioTracks = "audioTracks", videoTracks = "videoTracks"
    }
}

/// The media track.
@objc
public class MediaTrack: OCastMessage {
    
    /// The track identifier.
    public let trackId: String
    
    /// The ISO639-1/2 language.
    public let language: String
    
    /// The name.
    public let label: String
    
    /// `true` if the track is enabled, otherwise `false`.
    public let enabled: Bool
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
    /// :nodoc:
    case invalidMetadata = 9997
    case invalidPlaybackStatus = 9998
    case invalidErrorCode = 9999
}

// MARK: - Media Commands

/// The command to prepare a media.
@objc
@objcMembers
public class MediaPrepareCommand: OCastMessage {
    
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
    
    /// The media type. See `MediaType`
    public let mediaType: MediaType
    
    /// The media transfer mode. See `MediaTransferMode`
    public let transferMode: MediaTransferMode
    
    /// `true` if the media must be lauched automatically, othewise `false` (can be done with play).
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

/// The command to set a media track.
@objc
@objcMembers
public class MediaTrackCommand: OCastMessage {
    
    /// The track identifier.
    public let trackId: String

    /// The media track type. See `MediaTrackType`
    public let type: MediaTrackType
    
    /// `true` to enable the track, `false` to disable it.
    public let enable: Bool
    
    public init(trackId: String, type: MediaTrackType, enable: Bool) {
        self.type = type
        self.trackId = trackId
        self.enable = enable
    }
}

/// The command to play a media.
@objc
@objcMembers
public class MediaPlayCommand: OCastMessage {
    
    /// The position in seconds.
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

/// The command to stop a media.
@objc
public class MediaStopCommand: OCastMessage {}

/// The command to resume a media.
@objc
public class MediaResumeCommand: OCastMessage {}

/// The command to set the volume of a media
@objc
@objcMembers
public class MediaVolumeCommand: OCastMessage {
    
    // The volume level between 0 and 1.
    public let volume: Float
    
    public init(volume: Float) {
        self.volume = volume
    }
}

/// The command to pause a media.
@objc
public class MediaPauseCommand: OCastMessage {}

/// The command to seek a media.
@objc
@objcMembers
public class MediaSeekCommand: OCastMessage {
    
    // The position which to seek in seconds.
    public let position: Double
    
    public init(position: Double) {
        self.position = position
    }
}

/// The command to retrieve the media playback status.
@objc
public class MediaGetPlaybackStatusCommand: OCastMessage {}

/// The command to retrieve the media metadata.
@objc
public class MediaGetMetadataCommand: OCastMessage {}

/// The command to mute a media.
@objc
@objcMembers
public class MediaMuteCommand: OCastMessage {
    
    /// `true`to mute the media, `false` to unmute it.
    public let mute: Bool
    
    public init(mute: Bool) {
        self.mute = mute
    }
}
