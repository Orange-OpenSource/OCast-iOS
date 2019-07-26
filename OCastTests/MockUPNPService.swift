//
// MockUPNPService.swift
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
@testable import OCast

/// Class to mock an UPNP service.
class MockUPNPService: UPNPServiceProtocol {
    
    var device: UPNPDevice?
    
    init(device: UPNPDevice?) {
        self.device = device
    }
    
    func device(fromLocation location: String, completionHandler: @escaping UPNPServiceProtocolCompletionHandler) {
        if let device = device {
            completionHandler(.success(device))
        } else {
            completionHandler(.failure(.badContent))
        }
    }
}
