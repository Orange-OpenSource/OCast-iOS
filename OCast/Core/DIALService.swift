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

public enum DIALError: Error {
    case httpRequest(HTTPRequestError)
    case badContentResponse
}

public enum DIALState: String {
    case running, stopped, hidden
}

public struct DIALApplicationInfo {
    public let app2appURL: String?
    public let version: String?
    public let runLink: String?
    public let name: String
    public let state: DIALState
}

/// Extension to manage logs.
extension DIALApplicationInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "DIALApplicationInfo(app2appURL: \(String(describing: app2appURL)), state: \(state))"
    }
}

public class DIALService {
    
    private let baseURL: String
    
    /// The URLSession used to launch the requests.
    private let urlSession: URLSessionProtocol
    
    public init(forURL url: String, urlSession: URLSessionProtocol = URLSession(configuration: .default)) {
        baseURL = url
        self.urlSession = urlSession
    }
    
    /// Get application info
    ///
    /// - Parameter completion: result
    public func info(ofApplication name: String, completion: @escaping (Result<DIALApplicationInfo, DIALError>) -> Void) {
        HTTPRequest.launch(urlSession: urlSession, method: .GET, url: "\(baseURL)/\(name)") { result in
            switch result {
            case .failure(let httpError):
                DispatchQueue.main.async { completion(.failure(.httpRequest(httpError))) }
                return
            case .success((let data, _)): // success
                guard let data = data,
                    let element = XMLReader().parse(data: data)?["service"],
                    let appName = element["name"]?.value,
                    let stateValue = element["state"]?.value,
                    let state = DIALState(rawValue: stateValue) else {
                        DispatchQueue.main.async { completion(.failure(.badContentResponse)) }
                        return
                }
                
                let app2app = element["additionalData"]?["ocast:X_OCAST_App2AppURL"]?.value
                let version = element["additionalData"]?["ocast:X_OCAST_Version"]?.value
                let runLink = element["link"]?.attributes?["href"]
                
                let info = DIALApplicationInfo(app2appURL: app2app, version: version, runLink: runLink, name: appName, state: state)
                DispatchQueue.main.async { completion(.success(info)) }
            }
        }
    }
    
    /// Start the application
    ///
    /// - Parameter completion: result
    public func start(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
        HTTPRequest.launch(urlSession: urlSession, method: .POST, url: "\(baseURL)/\(name)", successCode: 201) { result in
            switch result {
            case .failure(let httpError):
                DispatchQueue.main.async { completion(.failure(.httpRequest(httpError))) }
            case .success:
                DispatchQueue.main.async { completion(.success(())) }
            }
        }
    }
    
    /// Stop the application
    ///
    /// - Parameter completion: result
    public func stop(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
        info(ofApplication: name) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let info):
                var stopLink: String!
                if  let runLink = info.runLink,
                    let url = URL(string: runLink),
                    url.host != nil {
                    stopLink = runLink
                } else if let runLink = URL(string: self.baseURL)?.appendingPathComponent(info.runLink ?? "run").absoluteString {
                    stopLink = runLink
                } else {
                    completion(.failure(.badContentResponse))
                    return
                }
                HTTPRequest.launch(urlSession: self.urlSession, method: .DELETE, url: stopLink, completion: { result in
                    switch result {
                    case .failure(let httpError):
                        DispatchQueue.main.async { completion(.failure(.httpRequest(httpError))) }
                    case .success:
                        DispatchQueue.main.async { completion(.success(())) }
                    }
                })
            }
        }
    }
}
