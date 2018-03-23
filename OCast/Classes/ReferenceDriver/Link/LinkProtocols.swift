//
// LinkProtocols.swift
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
import OCast

protocol LinkProtocol {
    func onEvent(payload: EventStructure)
    func onLinkConnected(from identifier: Int8)
    func onLinkDisconnected(from identifier: Int8)
    func onLinkFailure(from identifier: Int8)
}

protocol LinkBuildProtocol {
    static func make(from sender: Any, linkProfile: LinkProfile) -> LinkBuildProtocol
}

struct LinkProfile {
    let identifier: Int8
    let ipAddress: String
    let needsEvent: Bool
    let app2appURL: String
    let certInfo: CertificateInfo?
}
