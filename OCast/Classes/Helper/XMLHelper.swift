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

protocol XMLHelperProtocol {
    func didEndParsing(for application: String, result: [String: String], attributes: [String: [String: String]])
    func didParseWithError(for application: String, with error: Error, diagnostic: [String])
}

final class XMLHelper: NSObject, XMLParserDelegate {

    var delegate: XMLHelperProtocol?
    var application: String
    var collectedCharacters = ""

    internal struct KeyDefinition {
        let name: String
        let isMandatory: Bool
    }

    var keyList: [KeyDefinition] = []

    var keyResult: [String: String] = [:]
    var keyAttributes: [String: [String: String]] = [:]

    init(fromSender: XMLHelperProtocol, for application: String) {
        delegate = fromSender
        self.application = application
    }

    convenience init(fromSender: XMLHelperProtocol) {
        self.init(fromSender: fromSender, for: "")
    }

    // MARK: - XML Helper interface

    func parseDocument(data: Data, withKeyList keyList: [KeyDefinition]) {
        self.keyList = keyList
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // MARK: - Parser protocol

    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        delegate?.didParseWithError(for: application, with: parseError, diagnostic: [])
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {

        let keyElement = keyList.filter { keyDefinition -> Bool in
            return keyDefinition.name == elementName
        }

        if let keyName = keyElement.first?.name {
            keyResult[keyName] = collectedCharacters
        }

        collectedCharacters = ""
    }

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {

        let keyElement = keyList.filter { keyDefinition -> Bool in
            return keyDefinition.name == elementName
        }

        if keyElement.first?.name != nil {
            keyAttributes[elementName] = attributeDict
            collectedCharacters = ""
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        collectedCharacters += string
    }

    func parserDidEndDocument(_: XMLParser) {

        let result = checkParsing()

        if result.isOK {
            delegate?.didEndParsing(for: application, result: keyResult, attributes: keyAttributes)

        } else {

            let error = NSError(domain: "OCastXMLErrorDomain", code: 1, userInfo: ["Fatal error": "Missing required parameter(s)"])
            delegate?.didParseWithError(for: application, with: error, diagnostic: result.missingKeys)
        }
    }

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Private functions

    private func checkParsing() -> (isOK: Bool, missingKeys: [String]) {

        let result = keyList.filter { element -> Bool in
            return element.isMandatory && (keyResult[element.name] == nil)
        }

        if result.count == 0 {
            return (true, [])
        }

        let missingKeys = result.map { element -> String in
            return element.name
        }

        return (false, missingKeys)
    }
}
