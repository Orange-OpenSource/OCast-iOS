//
//  ReferenceDriverErrorCode.swift
//
// Copyright 2018 Orange
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

/// The reference driver error code
///
/// - privateSettingsNotAllowed: Private settings not allowed.
/// - moduleNotConnected: Module not connected. Cannot send a payload.
/// - linkConnectionLost: Link connection lost.
@objc public enum ReferenceDriverErrorCode: Int {
    case privateSettingsNotAllowed = 8000
    case moduleNotConnected = 8001
    case linkConnectionLost = 8002
}
