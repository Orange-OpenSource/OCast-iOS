//
// XMLHelper.swift
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

final class XMLHelper: NSObject, XMLParserDelegate {

    public var completionHandler:((_ error: Error?, _ keys: [String: String]?, _ keysAttributes:[String: [String: String]]?) -> Void)?

    private var collectedCharacters = ""
    private var keyResult: [String: String] = [:]
    private var keyAttributes: [String: [String: String]] = [:]
    
    // MARK: - public methods
    func parseDocument(data: Data) {
        self.keyResult = [:]
        self.keyAttributes = [:]
        collectedCharacters = ""
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // MARK: - XMLParserDelegate methods
    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        completionHandler?(parseError, nil, nil)
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {

        keyResult[elementName] = collectedCharacters
        collectedCharacters = ""
    }

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {

        keyAttributes[elementName] = attributeDict
        collectedCharacters = ""
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        collectedCharacters += string
    }

    func parserDidEndDocument(_: XMLParser) {
        completionHandler?(nil, keyResult, keyAttributes)
    }

}
