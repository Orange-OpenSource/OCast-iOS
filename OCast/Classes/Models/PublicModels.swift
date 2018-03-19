//
// PublicModels.swift
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
//

import Foundation

/**
 Used to transfer certificate information from the DeviceManager to the Driver.
 Not implemented in this version.
 */

@objc public final class CertificateInfo: NSObject {

    public var clientCertificate: String
    public var serverCACertificate: String
    public var serevrRootCACertificate: String
    public var password: String

    /**
     Initializes a new certificate information class.

     - Parameters:
         - clientCert: client certificate
         - serverCACert: server certificate
         - serverRootCACert: server root certificate
         - password: password to decode the certificate
     */

    public init(clientCert: String, serverCACert: String, serverRootCACert: String, password: String) {
        clientCertificate = clientCert
        serverCACertificate = serverCACert
        serevrRootCACertificate = serverRootCACert
        self.password = password
    }
}

/**
 Used to describe a device.
 - Parameters:
     - baseURL: base URL of the device
     - ipAddress: IP address
     - servicePort: service port
     - deviceID: unique device ID (aka USN)
     - friendlyName: friendly name
     - manufacturer: manufacturer's name
     - modelName: model name
 */

@objc public final class Device: NSObject {
    /// base URL of the device
    public var baseURL: URL
    /// IP address
    public var ipAddress: String
    /// service port
    public var servicePort: UInt16
    /// unique device ID (aka USN)
    public var deviceID: String
    /// friendly name
    public var friendlyName: String
    /// manufacturer's name
    public var manufacturer: String
    /// model name
    public var modelName: String

    init(baseURL: URL, ipAddress: String, servicePort: UInt16, deviceID: String, friendlyName: String, manufacturer: String, modelName: String?) {
        self.baseURL = baseURL
        self.ipAddress = ipAddress
        self.servicePort = servicePort
        self.deviceID = deviceID
        self.friendlyName = friendlyName
        self.manufacturer = manufacturer
        self.modelName = modelName!
    }
}

/// :nodoc:
@objc public final class ApplicationDescription: NSObject {
    public let app2appURL: String
    public let version: String
    public let rel: String
    public let href: String
    public let name: String

    public init(app2appURL: String, version: String, rel: String, href: String, name: String) {
        self.app2appURL = app2appURL
        self.version = version
        self.rel = rel
        self.href = href
        self.name = name
    }
}

/// :nodoc:
// Not impemented in this version.
@objc public final class StatusInfo: NSObject {
    public let version: String?
    public let state: String?
    public let progress: Int?

    @objc public init(version: String?, state: String?, progress: Int) {
        self.version = version
        self.state = state
        self.progress = progress
    }
}

/**
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

@objc public enum MediaErrorCode: Int {
    case noError = 0
    case invalidService = 2404
    case noImplementation = 2400
    case missingParameter = 2422
    case invalidPlayerState = 2412
    case playerNotReady = 2413
    case invalidTrack = 2414
    case unknowMediaType = 2415
    case unknownTransferMode = 2006
    case unknownError = 2500
    /// :nodoc:
    case unvalidErrorCode = 9999
}

/**
 Media type

 - `.audio`: audio type
 - `.image`: image type
 - `.video`: viedo type

 */
@objc public enum MediaType: Int {
    case audio
    case image
    case video
}

/**
 Transfer mode

 - `.buffered`: buffered type
 - `.streamed`: streamed type

 */

@objc public enum TransferMode: Int {
    case buffered
    case streamed
}

/// Describes the media to be casted.

@objc public final class MediaPrepare: NSObject {

    /**
     Initializes a new media description.
     - Parameters:
         - url: URL where to play the media from
         - frequency: media status report reception frequency (in seconds). Set to 0 for no reports.
         - title: media title
         - subtitle: media subtitle
         - logo: URL where to fetch the media logo
         - mediaType: media type. See `MediaType` for details.
         - transferMode: transfer mode. See `TransferMode` for details.
         - autoplay: `true` to start the media automatically.  `false` otherwise. In this case, the `play` command should be used to cast the media (See `MediaController`).
     */
    public init(url: URL, frequency: UInt, title: String, subtitle: String, logo: URL, mediaType: MediaType, transferMode: TransferMode, autoplay: Bool) {
        self.url = url
        self.frequency = frequency
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self.mediaType = mediaType
        self.transferMode = transferMode
        self.autoplay = autoplay
    }

    public let url: URL
    public let frequency: UInt
    public let title: String
    public let subtitle: String
    public let logo: URL
    public let mediaType: MediaType
    public let transferMode: TransferMode
    public let autoplay: Bool
}

/**
 Player state

 - `.playing`: playing
 - `.buffering`: buffering
 - `.idle`: idle
 - `.paused`: paused
 - `.stopped`: stopped
 - `.cancelled`: cancelled

 */

@objc public enum PlayerState: Int {
    case playing = 1
    case buffering
    case idle
    case paused
    case stopped
    case cancelled
}

/// Describes the status of the current media.
@objc public final class PlaybackStatus: NSObject {
    /// media duration in seconds
    public let duration: Double
    /// mute indicator
    public let mute: Bool
    /// media position in seconds
    public let position: Double
    /// player state. See `PlayerState` for details.
    public let state: PlayerState
    /// media volume level (in [0..1] interval)
    public let volume: Double

    init(duration: Double, mute: Bool, position: Double, state: PlayerState, volume: Double) {
        self.duration = duration
        self.mute = mute
        self.position = position
        self.state = state
        self.volume = volume
    }
}

/**
 Track type

 - `.audio`: audio type
 - `.text`: text type
 - `.video`: viedo type
 - `.undefined`: undefined type

 */

@objc public enum TrackType: Int {
    case audio = 0
    case text
    case video
    case undefined
}

/// Describes a media track.

@objc public final class TrackDescription: NSObject {
    /// track id
    public let id: String
    /// track status
    public let enabled: Bool
    /// track language
    public let language: String
    /// track label
    public let label: String

    init(id: String, enabled: Bool, language: String, label: String) {
        self.id = id
        self.enabled = enabled
        self.language = language
        self.label = label
    }
}

/// Describes the metadata of the current media.

@objc public final class MetaDataChanged: NSObject {
    /// media title
    public let title: String
    /// media subtitle
    public let subtitle: String
    /// media logo
    public let logo: URL
    /// media type. See `MediaType` for details.
    public let mediaType: MediaType
    /// list of available audio tracks. See `TrackDescription` for details.
    public let audioTracks: [TrackDescription]?
    /// list of available video tracks. See `TrackDescription` for details.
    public let videoTracks: [TrackDescription]?
    /// list of available text tracks. See `TrackDescription` for details.
    public let textTracks: [TrackDescription]?

    init(title: String, subtitle: String, logo: URL, mediaType: MediaType, audioTracks: [TrackDescription]?, videoTracks: [TrackDescription]?, textTracks: [TrackDescription]?) {
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self.mediaType = mediaType
        self.audioTracks = audioTracks
        self.videoTracks = videoTracks
        self.textTracks = textTracks
    }
}