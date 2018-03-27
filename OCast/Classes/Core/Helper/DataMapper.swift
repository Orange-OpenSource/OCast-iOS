//
// DataMapper.swift
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
 

struct DataMapper {

    // MARK: - Generic, ie, not hardware/manufacturer dependant

    func getBrowserData(with data: [String: Any]?) -> BrowserStructure? {

        guard let browserData = data else {

            OCastLog.error("DataMapper: Received data is not of the expected format.")
            return nil
        }

        let service = browserData["service"] as? String
        let data = browserData["data"] as? [String: Any]
        return BrowserStructure(service: service, data: data)
    }

    func getMediaControllerData(data: [String: Any]) -> StreamStructure? {

        guard let name = data["name"] as? String else {
            return nil
        }

        guard let params = data["params"] as? [String: Any] else {
            return nil
        }

        let options = data["options"] as? [String: Any]

        return StreamStructure(name: name, params: params, options: options)
    }

    func getMetaData(from data: StreamStructure) -> MetaDataChanged? {

        let logo = data.params["logo"] as? String ?? ""

        guard let logoURL = URL(string: logo) else {
            return nil
        }

        let audioTracks = getTracks(with: data.params["audioTracks"])
        let videoTracks = getTracks(with: data.params["videoTracks"])
        let textTracks = getTracks(with: data.params["textTracks"])

        if let mediaType = data.params["mediaType"] as? String {

            return MetaDataChanged(title: data.params["title"] as? String ?? "",
                                   subtitle: data.params["subtitle"] as? String ?? "",
                                   logo: logoURL,
                                   mediaType: mediaTypeToInt(for: mediaType),
                                   audioTracks: audioTracks,
                                   videoTracks: videoTracks,
                                   textTracks: textTracks)
        }

        return nil
    }

    func playerStateToInt(for state: String) -> PlayerState {
        switch state {
        case "playing": return PlayerState.playing
        case "buffering": return PlayerState.buffering
        case "idle": return PlayerState.idle
        case "paused": return PlayerState.paused
        case "stopped": return PlayerState.stopped
        case "cancelled": return PlayerState.cancelled
        default: return PlayerState.idle
        }
    }

    func mediaTypeToInt(for media: String) -> MediaType {
        switch media {
        case "audio": return MediaType.audio
        case "video": return MediaType.video
        case "image": return MediaType.image
        default: return MediaType.audio
        }
    }

    func getPlaybackStatus(with data: StreamStructure) -> PlaybackStatus {

        let duration = data.params["duration"] as? Double ?? 0.0
        let mute = data.params["mute"] as? Bool ?? true
        let position = data.params["position"] as? Double ?? 0.0
        let state = data.params["state"] as? String ?? "idle"
        let volume = data.params["volume"] as? Double ?? 0

        let stateEnum = DataMapper().playerStateToInt(for: state)

        return PlaybackStatus(duration: duration, mute: mute, position: position, state: stateEnum, volume: volume)
    }

    func getTracks(with data: Any?) -> [TrackDescription]? {

        if data == nil {
            return nil
        }

        guard let message = data as? Array<[String: Any]> else {
            return nil
        }

        return message.map { element -> TrackDescription in

            TrackDescription(id: element["trackId"] as? String ?? "",
                             enabled: element["enabled"] as? Bool ?? false,
                             language: element["language"] as? String ?? "",
                             label: element["label"] as? String ?? "")
        }
    }
}
