//
// ReferencePublicSettings.swift
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

extension ReferenceDriver: PublicSettings {
    
    // MARK: - Public settings
    open func getUpdateStatus(onSuccess: @escaping (StatusInfo) -> Void, onError: @escaping (NSError?) -> Void) {
        guard let link = links[.publicSettings] else {
            OCastLog.error("Reference Driver: Could not get the secured link.")
            // FIXME: create error
            onError(nil)
            return
        }
        
        let payload = Command(
            command: PublicSettingsConstants.COMMAND_STATUS,
            params: ["service" : PublicSettingsConstants.SERVICE_SETTINGS_DEVICE, "data": ["name": PublicSettingsConstants.COMMAND_STATUS, "params": [:], "options": [:]]])
        
        link.send(
            payload: payload,
            forDomain: ReferenceDomainName.settings.rawValue,
            onSuccess: {
                commandReply in
                guard let data = commandReply.message["data"] as? [String: Any],
                    let streamData = DataMapper().streamData(with: data),
                    let statusInfo = DataMapper().statusInfo(with: streamData) else {
                            // FIXME: create error
                            onError(nil)
                            return
                    }
                    onSuccess(statusInfo)
        }) { (error) in
            if let error = error {
                OCastLog.error("Reference Driver: Payload could not be sent: \(String(describing: error.userInfo[ReferenceDriver.ReferenceDriverErrorDomain]))")
            }
            onError (error)
        }
    }
    
    open func getDeviceID(onSuccess: @escaping (String) -> (), onError: @escaping (NSError?) -> ()) {
        guard let link = links[.publicSettings] else {
            OCastLog.error("Reference Driver: Could not get the secured link.")
            // FIXME: create error
            onError(nil)
            return
        }
        
        let payload = Command(
            command: PublicSettingsConstants.COMMAND_DEVICE_ID,
            params: ["service" : PublicSettingsConstants.SERVICE_SETTINGS_DEVICE, "data": ["name": PublicSettingsConstants.COMMAND_DEVICE_ID, "params": [:], "options": [:]]])
        
        link.send(
            payload: payload,
            forDomain: ReferenceDomainName.settings.rawValue,
            onSuccess: {
                commandReply in
                guard let data = commandReply.message["data"] as? [String: Any],
                    let streamData = DataMapper().streamData(with: data),
                    let id = streamData.params["id"] as? String else {
                        // FIXME: create error
                        onError(nil)
                        return
                }
                onSuccess(id)
        }) { (error) in
            if let error = error {
                OCastLog.error("Reference Driver: Payload could not be sent: \(String(describing: error.userInfo[ReferenceDriver.ReferenceDriverErrorDomain]))")
            }
            onError (error)
        }
    }
    
    open func didReceivePublicSettingsEvent(withMessage message: [String: Any]) {
        guard let data = message["data"] as? [String: Any],
            let streamData = DataMapper().streamData(with: data) else {
            OCastLog.debug("Reference Driver Public Settings : Receive a bad formatted message")
            return
        }
        
        if streamData.name == PublicSettingsConstants.EVENT_STATUS,
            let statusInfo = DataMapper().statusInfo(with: streamData) {
            
            publicSettingsEventDelegate?.didReceiveEvent(updateStatus: statusInfo)
        }
    }
}
