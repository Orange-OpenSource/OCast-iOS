//
// SynchronizedDictionary.swift
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

/// Class to synchronize a dictionary.
public struct SynchronizedDictionary<T: Hashable, U> {
    
    /// The synchronized dictionary.
    private var synchronizedDictionary = SynchronizedValue([T: U]())
    
    public init() {}
    
    /// Thread-safe subscript
    public subscript(key: T) -> U? {
        get {
            return synchronizedDictionary.read { $0[key] }
        }
        set {
            synchronizedDictionary.write { dictionary in
                dictionary[key] = newValue
            }
        }
    }
    
    /// Removes an item safely.
    ///
    /// - Parameter key: The key to remove.
    public func removeItem(forKey key: T) {
        synchronizedDictionary.write { dictionary in
            dictionary.removeValue(forKey: key)
        }
    }
    
    /// Removes all items safely.
    public func removeAll() {
        synchronizedDictionary.write { dictionary in
            dictionary.removeAll()
        }
    }
    
    /// Iterates the dictionary safely.
    ///
    /// - Parameter body: The key, value of the dictionary.
    public func forEach(_ body: (T, U) -> Void) {
        synchronizedDictionary.read { $0.forEach(body) }
    }
}

