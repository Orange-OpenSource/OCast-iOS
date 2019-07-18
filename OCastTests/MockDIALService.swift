//
// MockDIALService.swift
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

/// Class to mock the DIAL service.
class MockDIALService: DIALServiceProtocol {
    
    var responseDelay: Double = 0.5
    var dialApplicationInfo: DIALApplicationInfo?
    var dialInfoError: DIALError?
    var dialStartError: DIALError?
    var dialStopError: DIALError?
    private(set) var dialStartCalled = false
    
    init(applicationInfo: DIALApplicationInfo?,
         dialInfoError: DIALError? = nil,
         dialStartError: DIALError? = nil,
         dialStopError: DIALError? = nil) {
        self.dialApplicationInfo = applicationInfo
        self.dialInfoError = dialInfoError
        self.dialStartError = dialStartError
        self.dialStopError = dialStopError
    }
    
    func info(ofApplication name: String, completion: @escaping (Result<DIALApplicationInfo, DIALError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + responseDelay) {
            if let dialInfoError = self.dialInfoError {
                completion(.failure(dialInfoError))
            } else {
                completion(.success(self.dialApplicationInfo!))
            }
        }
    }
    
    func start(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
        dialStartCalled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + responseDelay) {
            if let dialStartError = self.dialStartError {
                completion(.failure(dialStartError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func stop(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + responseDelay) {
            if let dialStopError = self.dialStopError {
                completion(.failure(dialStopError))
            } else {
                completion(.success(()))
            }
        }
    }
}
