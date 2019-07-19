//
// DIALService.swift
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

/// The DIAL states.
///
/// - httpRequest: A HTTP error.
/// - badContentResponse: A bad content error when the DIAL response is not correct.
enum DIALError: Error {
    case httpRequest(HTTPRequestError)
    case badContentResponse
}

/// The DIAL states.
///
/// - running: The application is already running.
/// - stopped: The application is stopped.
/// - hidden: The application is hidden (not in foreground).
enum DIALState: String {
    case running, stopped, hidden
}

/// The DIAL application informations.
struct DIALApplicationInfo {
    
    /// The application name.
    public let name: String
    
    /// The application state.
    public let state: DIALState
    
    /// The OCast websocket URL.
    public let webSocketURL: String?
    
    /// The OCast version.
    public let version: String?
    
    /// The​ ​resource​ ​name​ ​of​ ​the​ ​running application.
    public let runLink: String?
}

/// Extension to manage logs.
extension DIALApplicationInfo: CustomDebugStringConvertible {
    var debugDescription: String {
        return "DIALApplicationInfo(webSocketURL: \(String(describing: webSocketURL)), state: \(state))"
    }
}

protocol DIALServiceProtocol {
    
    func info(ofApplication name: String, completion: @escaping (Result<DIALApplicationInfo, DIALError>) -> Void)
    
    func start(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void)
    
    func stop(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void)
}

/// Class to manage DIAL requests.
class DIALService: DIALServiceProtocol {
    
    /// The base URL.
    private let baseURL: String
    
    /// The URLSession used to launch the requests.
    private let urlSession: URLSessionProtocol
    
    // MARK: - Initializer
    
    public init(forURL url: String, urlSession: URLSessionProtocol = URLSession(configuration: .default)) {
        baseURL = url
        self.urlSession = urlSession
    }
    
    // MARK: - Private methods
    
    /// Builds the application URL from an application name.
    ///
    /// - Parameter applicationName: The application name.
    /// - Returns: The application URL.
    private func applicationURL(from applicationName: String) -> String {
        return "\(baseURL)/\(applicationName)"
    }
    
    // MARK: - Internal methods
    
    /// Retrieves the application information
    ///
    /// - Parameters:
    ///   - name: The application name to query.
    ///   - completion: The completion block called when the action completes.
    /// If the `DIALError` is nil, the information were successfully retrieved and are described in `DIALApplicationInfo` parameter.
    func info(ofApplication name: String, completion: @escaping (Result<DIALApplicationInfo, DIALError>) -> Void) {
        HTTPRequest.launch(urlSession: urlSession, method: .GET, url: applicationURL(from: name)) { result in
            switch result {
            case .failure(let httpError):
                DispatchQueue.main.async { completion(.failure(.httpRequest(httpError))) }
                return
            case .success((let data, _)):
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
                
                let info = DIALApplicationInfo(name: appName, state: state, webSocketURL: app2app, version: version, runLink: runLink)
                DispatchQueue.main.async { completion(.success(info)) }
            }
        }
    }
    
    /// Starts the given application.
    ///
    /// - Parameters:
    ///   - name: The application name to start.
    ///   - completion: The completion block called when the action completes.
    /// If the `DIALError` is nil, the application was successfully started.
    func start(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
        HTTPRequest.launch(urlSession: urlSession, method: .POST, url: applicationURL(from: name), successCode: 201) { result in
            switch result {
            case .failure(let httpError):
                DispatchQueue.main.async { completion(.failure(.httpRequest(httpError))) }
            case .success:
                DispatchQueue.main.async { completion(.success(())) }
            }
        }
    }
    
    /// Stops the given application.
    ///
    /// - Parameters:
    ///   - name: The application name to stop.
    ///   - completion: The completion block called when the action completes.
    /// If the `DIALError` is nil, the application was successfully stopped.
    func stop(application name: String, completion: @escaping (Result<Void, DIALError>) -> Void) {
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
                } else if let runLink = URL(string: self.applicationURL(from: name))?.appendingPathComponent(info.runLink ?? "run").absoluteString {
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
