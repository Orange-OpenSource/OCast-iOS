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

protocol BrowserDelegate {
    func sendBrowserData(data: DriverDataStructure, onSuccess: @escaping (DriverDataStructure) -> Void, onError: @escaping (NSError?) -> Void)
    func registerBrowser(for browser: DriverDelegate)}

final class Browser: NSObject, DriverDelegate {
    
    var streams: [String: DataStream] = [:]
    let driver: BrowserDelegate

    init(withDriver driver: BrowserDelegate) {
        self.driver = driver
        super.init()
        self.driver.registerBrowser(for: self)
    }

    func registerStream(for stream: DataStream) {
        streams[stream.serviceId] = stream
    }

    func sendData(data: [String: Any], for service: String, onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {

        let streamData: [String: Any] = [
            "service": service,
            "data": data,
        ]

        let paramsDictionanary = DriverDataStructure(message: streamData)

        driver.sendBrowserData(data: paramsDictionanary,
                               onSuccess: { params in

                                   OCastLog.debug("Browser: Received response from driver: \(String(describing: params.message))")
                                   onSuccess(params.message as? [String: Any])
                               },

                               onError: { error in
                                   OCastLog.error("Browser: Got an error from driver: \(String(describing: error)))")
                                   onError(error)
                               }
        )
    }

    // MARK: - DriverDelegate methods
    func onData(with data: DriverDataStructure) {

        guard let browserData = DataMapper().getBrowserData(with: data) else {
            OCastLog.error("Browser: Could not decode the data.")
            return
        }

        guard let dataForStream = browserData.data else {
            OCastLog.error("Browser: data for Stream was nil.")
            return
        }

        guard let service = browserData.service else {
            OCastLog.error("Browser: Service for Stream was nil.")
            return
        }

        // Forward the received message to the Stream matching the received service

        guard let stream = streams[service] else {
            OCastLog.error("Browser: Could not find any stream to pass the data.")
            return
        }

        OCastLog.debug("Stream: Got data from Browser for service \(service).")
        stream.onMessage(data: dataForStream)
    }
}
