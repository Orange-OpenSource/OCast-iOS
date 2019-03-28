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
//  OCastDomainSettings.swift
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation

// MARK: - Settings Objects
@objc
public class SettingsUpdateStatus: OCastMessage {
    public let state: String
    public let version: String
    public let progress: Int
}

@objc
public class SettingsDeviceID: OCastMessage {
    public let id: String
}

@objc
public class InputGamepadAxes: OCastMessage {
    public let x: Float
    public let y: Float
    public let num : Int
}

// MARK: - Settings Commands
@objc public class SettingsGetUpdateStatusCommand: OCastMessage {}
@objc public class SettingsGetDeviceIDCommand: OCastMessage {}

@objc
public class SettingsKeyPressedCommand: OCastMessage {
    public let key: String
    public let code: String
    public let ctrl: Bool
    public let alt: Bool
    public let shift: Bool
    public let meta: Bool
    public let location: Int
}

@objc
public class SettingsMouseEventCommand: OCastMessage {
    public let x: Int
    public let y: Int
    public let buttons: Int
}

@objc
public class SettingsGamepadEventCommand: OCastMessage {
    public let axes: [InputGamepadAxes]
    public let buttons: Int
}
