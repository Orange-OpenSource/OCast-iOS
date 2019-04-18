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
//  OCastDomainWebApp.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

// MARK: - WebApp Event

/**
 WebApp Status
 - `.connected`: connected
 - `.disconnected`: disconnected
 */

@objc public enum OCastWebAppStatusState: Int, RawRepresentable, Codable {
    case connected
    case disconnected
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        }
    }
    
    public init(rawValue: RawValue) {
        switch (rawValue) {
        case "connected": self = .connected
        case "disconnected": self = .disconnected
        default: self = .disconnected
        }
    }
}

@objc
public class OCastWebAppConnectedStatusEvent: OCastMessage {
    public let status: OCastWebAppStatusState
}
