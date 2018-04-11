//
// ReferenceDataMapper.swift
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

struct ReferenceDataMapper {

    // MARK: - Interface
    func referenceLink(for text: String) -> ReferenceLinkData? {
        if let data = text.data(using: .utf8) {
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                return ReferenceLinkData(destination: dictionary?["dst"] as? String ?? "",
                                              source: dictionary?["src"] as? String ?? "",
                                              type: dictionary?["type"] as? String ?? "",
                                              identifier: dictionary?["id"] as? Int ?? -1,
                                              status: dictionary?["status"] as? String,
                                              message: dictionary?["message"] as? [String: Any])

            } catch {
                OCastLog.error("ReferenceDataMapper: Serialization failed: \(error)")
                return nil
            }
        }

        return nil
    }

    // MARK: - Private functions
    private func statusInfo(with data: Any?) -> StatusInfo? {

        guard let message = data as? [String: Any] else {
            return nil
        }

        return StatusInfo(version: message["version"] as? String,
                          state: message["state"] as? String,
                          progress: message["progress"] as? Int ?? 0)
    }
}
