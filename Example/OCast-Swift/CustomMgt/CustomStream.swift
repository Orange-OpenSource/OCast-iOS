//
// CustomStream.swift
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
import OCast


final class CustomStream : DataStreamable {
    
    let serviceId = "org.ocast.custom"

    var messageSender: MessagerSender?

    var onDone : ([String : Any])->() = {_ in }
    
    func sendCustomMessage(with param:Int, onDone: @escaping ([String : Any])->()) {
        
        let dict = ["command":"START_APPLICATION \(param)","cmd_id":0, "url":"http://myWeb/myPage.htm"] as [String : Any]
        
        self.onDone = onDone
        sendMessage(with: dict, onSuccess: onSuccess(data:), onError: onError(error:))
    }
    
    //MARK: - DataStream methods implementation
    
    func onMessage(data: [String:Any]){
        OCastLog.debug(("-> CustomStream class: Data from Stream: \(data)"))
        onDone (data)
    }
    
    func onSuccess (data: [String:Any]?) {
        OCastLog.debug(("-> CustomStream class: OnSucesss \(String(describing: data))"))

    }
    
    func onError (error: NSError?) {
        OCastLog.debug(("-> CustomStream class: OnError \(String(describing: error))"))
       
    }
}

