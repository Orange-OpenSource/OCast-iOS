//
// ReferenceModel.swift
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


// Data structure for link layer

struct ReferenceLinkStructure {
    let destination: String
    let source: String
    let type: String
    let identifier: Int
    let status: String?
    let message: [String: Any]?
}

// Used for Event messages
struct EventStructure {
    let domain: String
    var message: DriverDataStructure
}

// Used for Command request and response
struct CommandStructure {
    
    let command: String
    var params: DriverDataStructure
    
    init(command: String = "", params: DriverDataStructure) {
        self.command = command
        self.params = params
    }
}
