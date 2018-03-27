//
// PrivateModels.swift
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

// MARK: - Internal Generic model structure


// Used to transfer data from/to the browser north interface
struct BrowserStructure {
    let service: String?
    let data: [String: Any]?
}

// Used to transfer data from/to the Stream north interface
struct StreamStructure {
    let name: String
    let params: [String: Any]
    let options: [String: Any]?
}

// Used by the MediaControler

extension MediaType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .image: return "image"
        case .video: return"video"
        }
    }
}

extension TransferMode {
    func toString() -> String {
        switch self {
        case .buffered: return "buffered"
        case .streamed: return "streamed"
        }
    }
}

extension PlayerState {
    func toString() -> String {
        switch self {
        case .playing: return "playing"
        case .buffering: return "buffering"
        case .idle: return "idle"
        case .paused: return "paused"
        case .stopped: return "stopped"
        case .cancelled: return "cancelled"
        }
    }
}

extension MediaErrorCode {
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

extension TrackType {
    func toString() -> String {
        switch self {
        case .audio: return "audio"
        case .video: return "video"
        case .text: return "text"
        case .undefined: return "undefined"
        }
    }
}
