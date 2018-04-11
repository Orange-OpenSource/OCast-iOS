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

    func metadata(with data: StreamData) -> MetaDataChanged? {
        
        guard let logoURL = URL(string: data.params["logo"] as? String ?? "") else {
            return nil
        }

        let audioTracks = tracks(with: data.params["audioTracks"])
        let videoTracks = tracks(with: data.params["videoTracks"])
        let textTracks = tracks(with: data.params["textTracks"])

        if let mediaType = data.params["mediaType"] as? String {
            return MetaDataChanged(title: data.params["title"] as? String ?? "",
                                   subtitle: data.params["subtitle"] as? String ?? "",
                                   logo: logoURL,
                                   mediaType: MediaType(type: mediaType),
                                   audioTracks: audioTracks,
                                   videoTracks: videoTracks,
                                   textTracks: textTracks)
        }

        return nil
    }

    func playbackStatus(with data: StreamData) -> PlaybackStatus {

        let duration = data.params["duration"] as? Double ?? 0.0
        let mute = data.params["mute"] as? Bool ?? true
        let position = data.params["position"] as? Double ?? 0.0
        let state = data.params["state"] as? String ?? "idle"
        let volume = data.params["volume"] as? Double ?? 0
        let stateEnum = PlayerState(state: state)

        return PlaybackStatus(duration: duration, mute: mute, position: position, state: stateEnum, volume: volume)
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
}
