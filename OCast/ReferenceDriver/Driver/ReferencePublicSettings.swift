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
        let payload = command(name: PublicSettingsConstants.COMMAND_STATUS,
                              service: PublicSettingsConstants.SERVICE_SETTINGS_DEVICE,
                              params: [:])
        execute(command: payload, onDomain: ReferenceDomainName.settings.rawValue, wrapper: { (reply) -> StatusInfo? in
            return DataMapper().statusInfo(with: reply)
        }, onSuccess: onSuccess, onError: onError)
    }
    
    open func getDeviceID(onSuccess: @escaping (String) -> (), onError: @escaping (NSError?) -> ()) {
        let payload = command(name: PublicSettingsConstants.COMMAND_DEVICE_ID,
                              service: PublicSettingsConstants.SERVICE_SETTINGS_DEVICE,
                              params: [:])
        execute(command: payload, onDomain: ReferenceDomainName.settings.rawValue, wrapper: { (reply) -> String? in
            return reply.params["id"] as? String
        }, onSuccess: onSuccess, onError: onError)
    }
    
    open func keyPressed(key: KeyValue, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        let payload = command(name: PublicSettingsConstants.COMMAND_KEY_PRESSED,
                              service: PublicSettingsConstants.SERVICE_SETTINGS_INPUT,
                              params: [
                                "key":key.key,
                                "code":key.code,
                                "ctrl":key.ctrl,
                                "alt": key.alt,
                                "shift": key.shift,
                                "meta": key.meta,
                                "location": key.location])

        execute(command: payload, onDomain: ReferenceDomainName.settings.rawValue, onSuccess: onSuccess, onError: onError)
    }
    
    open func mouseEvent(x: Int, y: Int, buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        let payload = command(name: PublicSettingsConstants.COMMAND_MOUSE_EVENT,
                              service: PublicSettingsConstants.SERVICE_SETTINGS_INPUT,
                              params: [
                                "x": x,
                                "y": y,
                                "buttons": buttons])
        execute(command: payload, onDomain: ReferenceDomainName.settings.rawValue, onSuccess: onSuccess, onError: onError)
    }
    
    open func gamepadEvent(axes: [GamepadAxes], buttons: Int, onSuccess:@escaping () -> (), onError:@escaping (NSError?) -> ()) {
        let axesJSON = axes.map { axe -> [String:Any] in
            ["num": axe.num, "x": axe.x, "y": axe.y]
        }
        let payload = command(name: PublicSettingsConstants.COMMAND_GAMEPAD_EVENT,
                              service: PublicSettingsConstants.SERVICE_SETTINGS_INPUT,
                              params: [
                                "axes":axesJSON,
                                "buttons": buttons])

        execute(command: payload, onDomain: ReferenceDomainName.settings.rawValue, onSuccess: onSuccess, onError: onError)
    }
    
    open func didReceivePublicSettingsEvent(withMessage message: [String: Any]) {
        guard let data = message["data"] as? [String: Any],
            let streamData = DataMapper().streamData(with: data) else {
            OCastLog.debug("Reference Driver Public Settings : Receive a bad formatted message")
            return
        }
        
        if streamData.name == PublicSettingsConstants.EVENT_STATUS,
            let statusInfo = DataMapper().statusInfo(with: streamData) {
            
            publicSettingsEventDelegate?.publicSettings(self, didReceiveUpdateStatus: statusInfo)
        }
    }
    
    // MARK: private methods
    private func execute(command: Command, onDomain domain: String, onSuccess: @escaping () -> (), onError: @escaping (NSError?) -> ()) {
        return execute(command: command,
                       onDomain: domain,
                       wrapper: { commandReply in return Void() },
                       onSuccess: onSuccess,
                       onError: onError)
    }
    
    private func execute<T>(command: Command,
                            onDomain domain: String,
                            wrapper:@escaping (StreamData) -> T?,
                            onSuccess: @escaping (T) -> (),
                            onError: @escaping (NSError?) -> ()) {
        
        guard let link = links[.publicSettings] else {
            let linkNotConnectedError = NSError(domain: ReferenceDriver.referenceDriverErrorDomain, code: 0, userInfo: ["Error": "Driver is not connected for public settings"])
            onError(linkNotConnectedError)
            return
        }
        
        link.send(payload: command,
                forDomain: domain,
                onSuccess: { commandReply in
                    
                    let invalidMessageError = NSError(domain: ReferenceDriver.referenceDriverErrorDomain,
                                                      code: 0,
                                                      userInfo: ["Error": "No valid message received \(commandReply)"])
                    
                    guard let _ = commandReply.message["service"] as? String,
                        let data = commandReply.message["data"] as? [String: Any],
                        let streamData = DataMapper().streamData(with: data) else {
                            onError(invalidMessageError)
                            return
                    }
                    
                    if let result = wrapper(streamData) {
                        onSuccess(result)
                    } else {
                        onError(invalidMessageError)
                    }
                       
                },
                onError: onError)
    }
    
    private func command(name: String, service: String, params: [String: Any] = [:], options: [String: Any] = [:]) -> Command {
        return Command(command: name,
                       params: ["service" : service, "data": ["name": name, "params": params, "options": options]])
    }
}
