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
//  DIALService.swift
//  OCast
//
//  Created by Christophe Azemar on 12/12/2018.
//

import Foundation

public enum DIALError : Error {
    case httpRequest(HTTPRequestError)
    case badContentResponse
}

public struct DIALApplicationInfo {
    public let app2appURL: String?
    public let version: String?
    public let rel: String?
    public let runLink: String?
    public let name: String?
    public let state: String?
}

public class DIALService {
    
    private var baseURL: String!
    
    public init(forURL url: String!) {
        baseURL = url
    }
    
    /// Get application info
    ///
    /// - Parameter completion: result
    public func info(ofApplication name: String, withCompletion completion: @escaping (Result<DIALApplicationInfo, DIALError>) -> ()) {
        HTTPRequest.launch(method: .GET, url: "\(baseURL!)/\(name)", httpHeaders: nil, body: nil) { result in
            switch result {
            case .failure(let httpError):
                completion(.failure(.httpRequest(httpError)))
                return
            case .success(let data): // success
                guard let data = data,
                    let element = OCastXMLParser().parse(data: data)?["service"] else {
                        completion(.failure(.badContentResponse))
                        return
                }
                let state = element["state"]?.value
                let app2app = element["additionalData"]?["ocast:X_OCAST_App2AppURL"]?.value
                let version = element["additionalData"]?["ocast:X_OCAST_Version"]?.value
                let rel = element["link"]?.attributes?["rel"]
                let runLink = element["link"]?.attributes?["href"]
                let appName = element["name"]?.value
                let info = DIALApplicationInfo(app2appURL: app2app, version: version, rel: rel, runLink: runLink, name: appName, state: state)
                completion(.success(info))
            }
        }
    }
    
    /// Start the application
    ///
    /// - Parameter completion: result
    public func start(application name: String, withCompletion completion: @escaping (Result<Bool, DIALError>) -> ()) {
        HTTPRequest.launch(method: .POST, url: "\(baseURL!)/\(name)", httpHeaders: nil, body: nil) { result in
            switch result {
            case .failure(let httpError):
                completion(.failure(.httpRequest(httpError)))
            case .success(_):
                completion(.success(true))
            }
        }
    }
    
    /// Stop the application
    ///
    /// - Parameter completion: result
    public func stop(application name: String, withCompletion completion: @escaping (Result<Bool, DIALError>) -> ()) {
        info(ofApplication:name) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let info):
                if let runLink = info.runLink {
                    HTTPRequest.launch(method: .DELETE, url: runLink, httpHeaders: nil, body: nil, completion: { result in
                        switch result {
                        case .failure(let httpError):
                            completion(.failure(.httpRequest(httpError)))
                        case .success(_):
                            completion(.success(true))
                        }
                    })
                } else {
                    completion(.failure(.badContentResponse))
                }
            }
        }
    }
    
}
