//
// SSDPResponseParser.swift
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

/// Class to parse a SSDP M-SEARCH response.
class SSDPResponseParser {
    
    /// The first request line.
    private let ssdpMSearchRequestLine = "HTTP/1.1 200 OK"
    
    // MARK: Internal methods
    
    /// Parses a response to build a new `SSDPMSearchResponse`.
    ///
    /// - Parameter response: The response to parse.
    /// - Returns: The `SSDPMSearchResponse` created.
    func parse(response: String) -> SSDPMSearchResponse? {
        let scanner = Scanner(string: response)
        
        // Parse request line to handle only M-SEARCH response
        guard let requestLine = parseLine(scanner: scanner),
            requestLine == ssdpMSearchRequestLine else { return nil }
        
        // Parse the headers
        let headers = parseHeaders(scanner: scanner)
        
        return SSDPMSearchResponse(from: headers)
    }

    // MARK: Private methods
    
    /// Parses the response headers.
    ///
    /// - Parameter scanner: The scanner used to parse the response.
    /// - Returns: The `SSDPHeaders` filled after the parsing.
    private func parseHeaders(scanner: Scanner) -> SSDPHeaders {
        var headers = SSDPHeaders()
        
        var line = parseLine(scanner: scanner)
        while let newLine = line {
            let keyValue = newLine.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
            if keyValue.count == 2,
                let ssdpHeader = SSDPHeader(rawValue: String(keyValue[0]).uppercased()) {
                headers[ssdpHeader] = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            line = parseLine(scanner: scanner)
        }
        
        return headers
    }
    
    /// Parses a response line.
    ///
    /// - Parameter scanner: The scanner used to parse the response.
    /// - Returns: The new parsed line.
    private func parseLine(scanner: Scanner) -> String? {
        guard !scanner.isAtEnd else { return nil }
        
        var line: NSString?
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &line)
        
        return line as String?
    }
}
