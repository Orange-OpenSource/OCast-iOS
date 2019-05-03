//
// MockURLSession.swift
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

/// Structure to represent a mocked response.
struct MockURLSessionResponse {
    let data: Data?
    let error: Error?
    let statusCode: Int
    let headers: [String: String]?
}

/// Class to mock an URLSession.
class MockURLSession: URLSessionProtocol {
    
    /// The request.
    private(set) var request: URLRequest?
    
    /// The task to launch.
    private(set) var mockURLSessionDataTask: MockURLSessionDataTask?
    
    /// Indicates if the method `finishTasksAndInvalidate` is called.
    private(set) var finishTasksAndInvalidateCalled = false
    
    private let response: MockURLSessionResponse
    
    init(response: MockURLSessionResponse) {
        self.response = response
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        self.request = request
        
        let httpResponse = HTTPURLResponse(url: request.url!, statusCode: response.statusCode, httpVersion: "HTTP/1.1", headerFields: response.headers)!
        completionHandler(response.data,
                          httpResponse,
                          response.error)
        
        mockURLSessionDataTask = MockURLSessionDataTask()
        
        return mockURLSessionDataTask!
    }
    
    func finishTasksAndInvalidate() {
        finishTasksAndInvalidateCalled = true
    }
}

/// Class to mock an URLSessionDataTask.
class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    
    /// Indicates if the method `resume` is called.
    private(set) var resumeCalled = false
    
    func resume() {
        resumeCalled = true
    }
}
