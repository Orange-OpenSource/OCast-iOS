//
// ReferencePublicSettings.swift
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
import OCast

extension ReferenceDriver: DriverPublicSettingsProtocol {

    // MARK: - Public settings

    public func getUpdateStatus(onSuccess _: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {

        // The public settings are not available in this version.

        let error = NSError(domain: "Reference Driver", code: 0, userInfo: ["Error": "Public Settings are not impelemented in this version."])
        onError(error)
    }
}
