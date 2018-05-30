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


public struct OCastData {
    public let destination: String
    public let source: String
    public let type: String
    public let identifier: Int
    public let status: String?
    public let message: [String: Any]?
}

public struct DataMapper {
    
    public init() {
    
    }
    
    // MARK: - Generic, ie, not hardware/manufacturer dependant
    public func decodeOCastData(for text: String) -> OCastData? {
        if let data = text.data(using: .utf8) {
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                return OCastData(destination: dictionary?["dst"] as? String ?? "",
                                 source: dictionary?["src"] as? String ?? "",
                                 type: dictionary?["type"] as? String ?? "",
                                 identifier: dictionary?["id"] as? Int ?? -1,
                                 status: dictionary?["status"] as? String,
                                 message: dictionary?["message"] as? [String: Any])
                
            } catch {
                OCastLog.error("DataMapper: Serialization failed: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    func browserData(with data: [String: Any]) -> BrowserData {
        let service = data["service"] as? String
        let data = data["data"] as? [String: Any]
        return BrowserData(service: service, data: data)
    }
    
    func mediaData(with data: [String: Any]) -> StreamData? {
        
        guard let name = data["name"] as? String,
            let params = data["params"] as? [String: Any] else {
                return nil
        }
        let options = data["options"] as? [String: Any]
        
        return StreamData(name: name, params: params, options: options)
    }
    
    func metadata(with data: StreamData) -> Metadata? {
        return metadata(with: data.params)
    }
    
    func metadata(with data: [String: Any]) -> Metadata? {
        guard let mediaType = data["mediaType"] as? String,
            let logo = data["logo"] as? String,
            let logoURL = URL(string: logo) else { return nil }
        
        let audioTracks = tracks(with: data["audioTracks"])
        let videoTracks = tracks(with: data["videoTracks"])
        let textTracks = tracks(with: data["textTracks"])
        
        return Metadata(title: data["title"] as? String ?? "",
                        subtitle: data["subtitle"] as? String ?? "",
                        logo: logoURL,
                        mediaType: MediaType(type: mediaType),
                        audioTracks: audioTracks,
                        videoTracks: videoTracks,
                        textTracks: textTracks)
    }
    
    func playbackStatus(with data: StreamData) -> PlaybackStatus? {
        return playbackStatus(with: data.params)
    }
    
    func playbackStatus(with data: [String: Any]) -> PlaybackStatus? {
        guard let state = data["state"] as? Int,
            let playerState = PlayerState(rawValue: state) else { return nil }
        
        let duration = data["duration"] as? Double ?? 0.0
        let mute = data["mute"] as? Bool ?? true
        let position = data["position"] as? Double ?? 0.0
        let volume = data["volume"] as? Double ?? 0
        
        return PlaybackStatus(duration: duration, mute: mute, position: position, state: playerState, volume: volume)
    }
    
    func tracks(with data: Any?) -> [TrackDescription]? {
        guard let message = data as? [[String: Any]] else {
            return nil
        }
        
        return message.map { element -> TrackDescription in
            TrackDescription(id: element["trackId"] as? String ?? "",
                             enabled: element["enabled"] as? Bool ?? false,
                             language: element["language"] as? String ?? "",
                             label: element["label"] as? String ?? "")
        }
    }
    
    func statusInfo(for data: Any?) -> StatusInfo? {
        guard let message = data as? [String:Any] else {
            return nil
        }
        
        return StatusInfo(version: message["version"]  as? String,
                          state:   message["state"]    as? String,
                          progress:message["progress"] as? Int ?? 0)
    }
}

/**
 Used to configure the SSL connection
 */
@objcMembers
@objc public final class SSLConfiguration: NSObject {
    /// The device certificates
    public var deviceCertificates: [Data]?
    /// The client certificate configuration (certificate and password)
    public var clientCertificate: SSLConfigurationClientCertificate?
    /// `true` (default) if you must validate the certificate host, `false` if the device hasn't a domain name.
    public var validatesHost: Bool
    /// `true` (default) to validate the entire SSL chain, otherwise `false`.
    public var validatesCertificateChain: Bool
    /// `true` to use self-signed certificates, otherwise `false` (default).
    public var disablesSSLCertificateValidation: Bool
    
    public override init() {
        validatesHost = true
        validatesCertificateChain = true
        disablesSSLCertificateValidation = false
    }
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - deviceCertificates: The device certificates (DER format) used for SSL one-way
    ///   - clientCertificate: The client certificate (PKCS12 format) and the password used for SSL two-way
    public convenience init(deviceCertificates: [Data]? = nil, clientCertificate: SSLConfigurationClientCertificate? = nil) {
        self.init()
        
        self.deviceCertificates = deviceCertificates
        self.clientCertificate = clientCertificate
    }
}

/**
 Used to configure the SSL client certificate
 */
@objcMembers
@objc public class SSLConfigurationClientCertificate: NSObject {
    /// The client certificate
    public let certificate: Data
    /// The password to import the certificate
    public let password: String
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - certificate: The certificate (PKCS12 format)
    ///   - password: The certificate password
    public init(certificate: Data, password: String) {
        self.certificate = certificate
        self.password = password
    }
}

/// Describes a Device
@objcMembers
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

    
    /// Create a Device
    ///
    /// - Parameters:
    ///   - baseURL: baseURL of the device
    ///   - ipAddress: IP address
    ///   - servicePort: service port
    ///   - deviceID: unique device ID (aka USN)
    ///   - friendlyName: friendly name
    ///   - manufacturer: manufacturer's name
    ///   - modelName: model name
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
@objcMembers
@objc public final class ApplicationDescription: NSObject {
    public let app2appURL: String?
    public let version: String
    public let rel: String?
    public let runLink: String?
    public let name: String

    public init(app2appURL: String?, version: String, rel: String?, href: String?, name: String) {
        self.app2appURL = app2appURL
        self.version = version
        self.rel = rel
        self.runLink = href
        self.name = name
    }
}

/// :nodoc:
// Not impemented in this version.
@objcMembers
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
    case unknownTransferMode = 2416
    case unknownError = 2500
    /// :nodoc:
    case invalidMetadata = 9997
    case invalidPlaybackStatus = 9998
    case invalidErrorCode = 9999
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
@objcMembers
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
    case unknown = 0
    case idle = 1
    case playing = 2
    case paused = 3
    case buffering = 4
}

/// Describes the status of the current media.
@objcMembers
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
@objcMembers
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
@objcMembers
@objc public final class Metadata: NSObject {
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
