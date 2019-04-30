//
// OCastXMLParser.swift
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

/// Class to represent a XML element.
class XMLElement {
    
    /// The element name.
    let name: String
    
    /// The element value.
    fileprivate (set) var value: String
    
    /// The element attributes dictionary.
    let attributes: [String: String]?
    
    /// The element parent (A weak is used to break the cycle between the parent and the child).
    fileprivate weak var parent: XMLElement?
    
    /// The element children.
    fileprivate var children = [XMLElement]()
    
    /// Parameterized initializer.
    ///
    /// - Parameters:
    ///   - name: The element name.
    ///   - value: The element value.
    ///   - attributes: The element attributes.
    init(name: String = "", value: String = "", attributes: [String: String]? = nil) {
        self.name = name
        self.value = value
        self.attributes = attributes
    }
    
    // MARK: Internal methods
    
    /// The subscript to browse the XML tree.
    ///
    /// - Parameter key: The key to search.
    subscript(key: String) -> XMLElement? {
        return children.first(where: { $0.name == key })
    }
}

/// Class to provide a XML parser used for SSDP and DIAL responses.
class OCastXMLParser: NSObject, XMLParserDelegate {
    
    /// The root element.
    private var rootElement = XMLElement()
    
    /// The current parent.
    private var currentParent: XMLElement?
    
    /// The current element.
    private var currentElement: XMLElement?
    
    // MARK: Internal methods
    
    /// Parses an XML document.
    ///
    /// - Parameter data: The XML buffer.
    /// - Returns: The XML root element used to browse the XML document.
    func parse(data: Data) -> XMLElement? {
        currentParent = rootElement
        
        let parser = XMLParser(data: data)
        parser.delegate = self
    
        return parser.parse() ? rootElement : nil
    }
    
    // MARK: XMLParserDelegate methods
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        // Create a new element and associate it to the parent
        currentElement = XMLElement(name: elementName, attributes: attributeDict)
        currentElement?.parent = currentParent
        currentParent?.children.append(currentElement!)
        currentParent = currentElement
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentElement?.value.append(string)
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        currentParent = currentParent?.parent
        currentElement = nil
    }
}
