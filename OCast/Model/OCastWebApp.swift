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
//  OCastWebApp.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

/// The web app service name
let OCastWebAppServiceName = "org.ocast.webapp"

/// The web app status
///
/// - connected: The web app is started and connected.
/// - disconnected: The web app is stopped and disconnected.
enum WebAppStatusState: String, Codable {
    case connected
    case disconnected
}

/// The connection status event.
class WebAppConnectedStatusEvent: OCastMessage {
    public let status: WebAppStatusState
}