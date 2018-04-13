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
    func send(data: [String: Any], onSuccess: @escaping (Any?) -> Void, onError: @escaping (NSError?) -> Void)
    func register(for delegate: DriverReceiverDelegate)
}

final class Browser: NSObject, DriverReceiverDelegate {
    
    var streams: [String: DataStream] = [:]
    
    weak var delegate: BrowserDelegate? {
        didSet {
            delegate?.register(for: self)
        }
    }

    func registerStream(for stream: DataStream) {
        streams[stream.serviceId] = stream
    }

    func sendData(data: [String: Any], for service: String, onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {

        let streamData: [String: Any] = [
            "service": service,
            "data": data,
        ]

        delegate?.send(
            data: streamData,
            onSuccess: {
                response in
                    OCastLog.debug("Browser: Received response from driver: \(String(describing: response))")
                    onSuccess(response as? [String: Any])
            },
            onError: {
                error in
                    OCastLog.error("Browser: Got an error from driver: \(String(describing: error)))")
                    onError(error)
            }
        )
    }

    // MARK: - DriverDelegate methods
    func didReceive( data: [String: Any]) {
        guard
            let dataForStream = DataMapper().browserData(with: data).data,
            let service = DataMapper().browserData(with: data)  .service else {
            OCastLog.error("Browser: Data is not well formatted \n(\(data)).")
            return
        }

        OCastLog.debug("Stream: Got data from Browser for service \(service).")
        streams[service]?.onMessage(data: dataForStream)
    }
}
