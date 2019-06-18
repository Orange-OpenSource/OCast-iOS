//
// SSDPMSearchRequest.swift
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

/// Struct to represent a SSDP M-SEARCH request.
struct SSDPMSearchRequest {
    
    /// The first request line.
    private let requestLine = "M-SEARCH * HTTP/1.1"
    
    /// The MAN header value.
    private let man = "\"ssdp:discover\""
    
    /// The host header value.
    let host: String
    
    /// The max time header value.
    let maxTime: Int
    
    /// The search target header value.
    let searchTarget: String
    
    /// The data which represents a M-SEARCH request given structure properties.
    var data: Data? {
        // Multiline adds the LF to obtain CRLF sequence
        return """
        \(requestLine)\r
        \(SSDPHeader.host.rawValue): \(host)\r
        \(SSDPHeader.man.rawValue): \(man)\r
        \(SSDPHeader.maxTime.rawValue): \(maxTime)\r
        \(SSDPHeader.searchTarget.rawValue): \(searchTarget)\r\n
        """.data(using: .utf8)
    }
}
