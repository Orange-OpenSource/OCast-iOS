//
// HttpManager.swift
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
// limitations under the License.
//

import Foundation

protocol HttpProtocol {
    func didReceiveHttpResponse(response: HTTPURLResponse, with data: Data?)
}

enum HttpCommand {
    case get
    case post
    case delete

    func name() -> String {
        switch self {
        case .delete:
            return "DELETE"
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}

extension HttpProtocol {

    func initiateHttpRequest(from _: HttpProtocol, with command: HttpCommand, to target: String, onSuccess: @escaping (_ response: HTTPURLResponse, _ data: Data?) -> Void, onError: @escaping (_ error: NSError?) -> Void) {

        guard let url = URL(string: target) else {
            OCastLog.error("Cannot create URL with target \(target)")
            let cause = "Target syntax error. Cannot send the Http request."
            let newError = NSError(domain: "HTTPManager", code: 0, userInfo: ["Http error": cause])
            onError(newError)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = command.name()

        let session = URLSession(configuration: URLSessionConfiguration.default)

        let task = session.dataTask(with: urlRequest) {
            data, response, error in

            if let error = error {
                OCastLog.error("\(String(describing: error))")
                let cause = String(describing: error)
                let newError = NSError(domain: "HTTPManager", code: 1, userInfo: ["Http error": cause])
                onError(newError)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {

                switch httpResponse.statusCode {
                case 200 ..< 300:
                    break
                default:
                    OCastLog.error("Request was not successful. httpResponse statusCode = \(httpResponse.statusCode)")
                    let cause = "Request was not successful"
                    let newError = NSError(domain: "HTTPManager", code: httpResponse.statusCode, userInfo: ["Http error": cause])
                    onError(newError)
                    return
                }

                OCastLog.debug(("HttpManager: Got an OK (\(httpResponse.statusCode))"))
                onSuccess(httpResponse, data)
            }
        }

        task.resume()
    }
}
