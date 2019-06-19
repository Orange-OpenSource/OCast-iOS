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
//  HTTPRequest.swift
//  OCast
//
//  Created by Christophe Azemar on 12/12/2018.
//

import Foundation

/// Protocol to represent an URLSession.
protocol URLSessionProtocol {
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
    func finishTasksAndInvalidate()
}

/// Protocol to represent an URLSessionDataTask.
protocol URLSessionDataTaskProtocol {
    
    func resume()
}

/// Extends URLSession to adopt URLSesionProtocol.
extension URLSession: URLSessionProtocol {
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}

/// Extends URLSessionDataTask to adopt URLSessionDataTaskProtocol
extension URLSessionDataTask: URLSessionDataTaskProtocol {}

enum HTTPRequestError : Error {
    case badURL
    case failed(String)
    case badCode(Int)
}

enum HTTPMethod: String {
    case GET, POST, DELETE
}

class HTTPRequest {

    public static func launch(urlSession: URLSessionProtocol,
                              method: HTTPMethod = .GET,
                              url urlString: String,
                              httpHeaders: [String : String]? = nil,
                              body: String? = nil,
                              successCode: Int = 200,
                              completion: ((Result<(Data?, [AnyHashable: Any]), HTTPRequestError>) -> ())?) {
        
        guard let url = URL(string: urlString) else {
            completion?(.failure(HTTPRequestError.badURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = httpHeaders
        urlRequest.httpBody = body?.data(using: .utf8)
        
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion?(.failure(.failed(error.localizedDescription)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if successCode == httpResponse.statusCode {
                    completion?(.success((data, httpResponse.allHeaderFields)))
                } else {
                    completion?(.failure(.badCode(httpResponse.statusCode)))
                }
            }
        }
        
        task.resume()
    }
}
