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

public enum HTTPRequestError : Error {
    case badURL
    case failed(String)
    case badCode(Int)
}

public enum HTTPMethod: String {
    case GET, POST, DELETE
}

public class HTTPRequest {
    
    public static func launch(method: HTTPMethod = .GET,
                              url urlString: String,
                              httpHeaders: [String : String]? = nil,
                              body: String? = nil,
                              completion: ((Result<Data?, HTTPRequestError>) -> ())?) {
        
        guard let url = URL(string: urlString) else {
            completion?(.failure(HTTPRequestError.badURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = httpHeaders
        urlRequest.httpBody = body?.data(using: .utf8)
        
        let urlSession = URLSession(configuration: .default)
        let task = urlSession.dataTask(with: urlRequest) {
            data, response, error in
            
            if let error = error {
                completion?(.failure(.failed(error.localizedDescription)))
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200 ..< 300:
                    break
                default:
                    completion?(.failure(.badCode(httpResponse.statusCode)))
                }
                
                completion?(.success(data))
            }
        }
        
        task.resume()
        urlSession.finishTasksAndInvalidate()
    }
}
