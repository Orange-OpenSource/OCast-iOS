//
// SynchronizedValue.swift
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

/// Class to synchronized a value to share it between threads.
class SynchronizedValue<T> {
    
    /// The dispatch queue to manage the concurrency.
    private let queue: DispatchQueue
    
    /// The value to synchronize.
    private var value: T
    
    init(_ value: T) {
        queue = DispatchQueue(label: "org.ocast.syncronizedvalue-" + UUID().uuidString, qos: .default, attributes: .concurrent)
        self.value = value
    }
    
    /// The synchronized value.
    var synchronizedValue: T {
        get {
            return queue.sync { value }
        }
        set {
            queue.async(flags: .barrier) { self.value = newValue }
        }
    }
    
    /// Performs a read concurrent access.
    ///
    /// - Parameter block: The block to execute.
    /// - Returns: The value read safely.
    func read<U>(_ block: (T) -> U) -> U {
        return queue.sync { block(value) }
    }
    
    /// Performs a write concurrent access.
    ///
    /// - Parameter block: The block to execute.
    func write(_ block: @escaping (inout T) -> Void) {
        queue.async(flags: .barrier) {
            block(&self.value)
        }
    }
}
