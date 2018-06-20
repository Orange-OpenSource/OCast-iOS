//
// Browser.swift
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

@objc public protocol BrowserDelegate {
    func send(data: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void)
    func register(for delegate: EventDelegate)
}

final class Browser: NSObject, EventDelegate {
    
    var streams: [String: DataStream] = [:]
    
    weak var delegate: BrowserDelegate? {
        didSet {
            delegate?.register(for: self)
        }
    }

    func register(stream: DataStream) {
        streams[stream.serviceId] = stream
    }

    func send(data: [String: Any], for service: String, onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {

        let streamData: [String: Any] = [
            "service": service,
            "data": data,
        ]

        delegate?.send(
            data: streamData,
            onSuccess: {
                message in
                    onSuccess(message?["data"] as? [String: Any])
            },
            onError: {
                error in
                    OCastLog.error("Browser: Got an error from driver: \(String(describing: error)))")
                    onError(error)
            }
        )
    }

    // MARK: - BrowserEventDelegate methods
    func didReceiveEvent(withMessage message: [String: Any]) {
        guard
            let service = message["service"] as? String,
            let data = message["data"] as? [String: Any] else {
                OCastLog.error("Browser: Data is not well formatted:(\(message)).")
            return
        }

        streams[service]?.onMessage(data: data)
    }
}
