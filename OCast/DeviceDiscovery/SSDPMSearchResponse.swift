//
// SSDPMSearchResponse.swift
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

/// Struct to represent a M-SEARCH response.
struct SSDPMSearchResponse {
    
    /// The location header value.
    let location: String
    
    /// The server header value.
    let server: String
    
    /// The USN header value.
    let USN: String
    
    /// The search target header value.
    let searchTarget: String
    
    /// Parameterized initializer to create a `SSDPMSearchResponse` from SSDP headers.
    ///
    /// - Parameter headers: The `SSDPHeaders` to browse to create the `SSDPMSearchResponse`.
    init?(from headers: SSDPHeaders) {
        guard let location = headers[.location],
            let searchTarget = headers[.searchTarget],
            let server = headers[.server],
            let USN = headers[.usn] else { return nil }
        
        self.location = location
        self.searchTarget = searchTarget
        self.server = server
        self.USN = USN
    }
}
