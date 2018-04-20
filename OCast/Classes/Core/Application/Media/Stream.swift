//
// Stream.swift
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

/**
 Used for custom messaging. 
 
 This protocol allows an application to send and receive customized messages to/from the web application.
 The code sample below shows a basic implementation of a class implementing the DataStreamable protocol. 
 
 See `ApplicationController` for custom stream management.

 ```
final class CustomStream : DataStream {
    
    //MARK: - DataStreamable: variable definition
    
    let serviceId = "my service"
    
    var messageSender: MessagerSender?
    
    //MARK: - DataStreamable: methods
    
    func onMessage(data: [String:Any]){
        print("-> CustomStream class: Received data from Stream: \(data)")
    }
    
    func sendCustomMessage() {
        
        let myMessage: [String : Any] = ["command":"START_APPLICATION","cmd_id":0, "url":"http://myWeb/myPage.htm"]
        
        sendMessage(with: myMessage, onSuccess: gotSuccess(data:), onError: gotError(error:))
    }
    
    func gotSuccess (data: [String:Any]?) {
        ...
    }
    
    func gotError (error: NSError?) {
        ...
    }
}

 ```
 */

@objc public protocol DataStream {
    /// The service ID representing the customized messages
    var serviceId: String { get }
    /// Provides access to the internal send mechanism. It just needs to be declared.
    var dataSender: DataSender? { get set }

    /**
     Gets called when data matching your service ID is received from the web application.
     - Parameter data: the data received from the web application
     */
    func onMessage(data: [String: Any])
}

/*
public extension DataStreamable {
    /**
     Used to send data to the web application.
     - Parameters:
         - message: the message to be sent. Needs to be in a [String:Any] format.
         - onSuccess: closure to be called in case of success
         - onFailure: closure to be called in case of error
     */
    public func sendMessage(with message: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {
        messageSender?.send(message: message, onSuccess: onSuccess, onError: onError)
    }
}*/

/// :nodoc:

@objc public protocol DataSender {
    func send(message: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void)
}

// MARK: Default DataSender  class
final class DefaultDataSender: DataSender {
    
    let browser: Browser
    let serviceId: String
    
    init(browser: Browser, serviceId: String) {
        self.browser = browser
        self.serviceId = serviceId
    }
    
    func send(message: [String: Any], onSuccess: @escaping ([String: Any]?) -> Void, onError: @escaping (NSError?) -> Void) {
        browser.send(data: message, for: serviceId, onSuccess: onSuccess, onError: onError)
    }
}
