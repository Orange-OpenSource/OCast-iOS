//
// Logger.swift
//
// Copyright 2019 Orange
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

/// The logger level.
///
/// - debug: Debug.
/// - info: Information.
/// - warning: Warnings.
/// - error: Errors.
/// - none: No logs.
public enum LoggerLevel: Int {
    case debug, info, warning, error, none
}

extension LoggerLevel: Comparable {
    public static func < (lhs: LoggerLevel, rhs: LoggerLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension LoggerLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return ""
        }
    }
}

/// The protocol to adopt to create a new logger.
public protocol LoggerProtocol {
    
    /// Logs a new message.
    ///
    /// - Parameters:
    ///   - logLevel: The log level.
    ///   - message: The message to display.
    ///   - file: The related file.
    ///   - line: The related line.
    ///   - function: The related function.
    func log(logLevel: LoggerLevel,
             _ message: @autoclosure () -> String,
             file: String,
             line: Int,
             function: String)
}

/// The console logger
struct ConsoleLogger: LoggerProtocol {
    
    func log(logLevel: LoggerLevel, _ message: () -> String, file: String, line: Int, function: String) {
        print("\(Date())(\(logLevel)) \((file as NSString).lastPathComponent):\(line) \(function): \(message())")
    }
}

/// The class to manage the logs. You can provide your own logger implementing the `LoggerProtocol` protocol.
public class Logger {
    
    /// The singleton instance.
    public static let shared = Logger()
    
    /// The logger used. Can be customized.
    public var logger: LoggerProtocol = ConsoleLogger()
    
    /// The minimum level (by default debug in debug mode, none in release mode).
    public var minimumLogLevel: LoggerLevel
    
    private init() {
        #if DEBUG
        minimumLogLevel = .warning
        #else
        minimumLogLevel = .none
        #endif
    }
    
    /// Adds a log if the log level is greater or equal than the minimum level.
    ///
    /// - Parameters:
    ///   - logLevel: The log level.
    ///   - message: The message to display.
    ///   - file: The file.
    ///   - line: The line.
    ///   - function: The function.
    func log(logLevel: LoggerLevel, _ message: @autoclosure () -> String, file: String = #file, line: Int = #line, function: String = #function) {
        if logLevel >= minimumLogLevel {
            logger.log(logLevel: logLevel, message(), file: file, line: line, function: function)
        }
    }
}

