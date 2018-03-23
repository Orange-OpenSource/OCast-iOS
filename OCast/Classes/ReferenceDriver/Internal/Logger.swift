//
// Logger.swift
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
/// :nodoc:
public struct Logger {

    /// Prints in debug only
    #if DEBUG
        public static func debug(_ msg: String, line: Int = #line, fileName: String = #file, funcName: String = #function) {
            let fname = (fileName as NSString).lastPathComponent
            print("\(Date())\(fname):\(funcName):\(line)", msg)
        }

    #else
        public static func debug(_: String, line _: Int = #line, fileName _: String = #file, funcName _: String = #function)
        {}
    #endif

    /// Prints an error message all case
    public static func error(_ msg: String, line: Int = #line, fileName: String = #file, funcName: String = #function) {
        let fname = (fileName as NSString).lastPathComponent
        print("\(fname):\(funcName):\(line)", "ReferenceDriver ERROR: \(msg)")
    }
}
