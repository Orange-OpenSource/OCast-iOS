//
// ReferenceDriverBrowser.swift
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
//

import Foundation

extension ReferenceDriver: DriverBrowserProtocol {
    
    public func onData(with data: DriverDataStructure) {
    }
    
    // MARK: - DriverBrowser Protocol

    public func sendBrowserData(data: DriverDataStructure, onSuccess: @escaping (DriverDataStructure) -> Void, onError: @escaping (NSError?) -> Void) {

        guard let link = links[LinkId.genericLink] as? ReferenceLink else {
            Logger.error("Reference Driver: Could not get the generic link.")
            return
        }

        let payload = CommandStructure(params: data)

        link.sendPayload(forDomain: .browser, withPaylaod: payload,

                         onSuccess: { cmdResponse in
                             Logger.debug("Reference Driver: Payload sent.")
                             onSuccess(cmdResponse.params)
                         },

                         onError: { error in

                             if let error = error {
                                 Logger.error("Reference Driver: Payload could not be sent: \(String(describing: error.userInfo[link.ErrorDomain]))")
                                 onError(error)
                             }
        })
    }

    public func registerBrowser(for browser: DriverBrowserProtocol) {
        self.browser = browser
    }
}
