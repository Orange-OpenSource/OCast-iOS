//
// SSDPHeader.swift
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

/// The SSDP header
///
/// - host: The host header.
/// - man: The man header.
/// - maxTime: The max time header.
/// - searchTarget: The search target header.
/// - location: The location header.
/// - server: The server header.
/// - usn: The unique service name header.
enum SSDPHeader: String {
    case host = "HOST"
    case man = "MAN"
    case maxTime = "MX"
    case searchTarget = "ST"
    case location = "LOCATION"
    case server = "SERVER"
    case usn = "USN"
}

/// The SSDP headers dictionary.
typealias SSDPHeaders = [SSDPHeader: String]
