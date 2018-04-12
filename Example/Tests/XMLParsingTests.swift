//
// XMLParsingTests.swift
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

import XCTest
@testable import OCast

class XMLParsingTests: XCTestCase, XMLHelperDelegate {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var testId = 0
    
    
    func test01_XMLData_OK () {
        
        // Manufacturer 01 regular device description
        
        testId = 1
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root xmlns=\"urn:schemas-upnp-org:device-1-0\" xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\"><specVersion><major>1</major><minor>0</minor></specVersion><URLBase>http://192.168.1.33:56789</URLBase><device><deviceType>urn:schemas-upnp-org:device:dail:1</deviceType><friendlyName>friendly name 01</friendlyName><manufacturer>Manufacurer 01</manufacturer><modelName>Model Name 01</modelName><UDN>device ID 01</UDN><serviceList><service><serviceType>urn:schemas-upnp-org:service:dail:1</serviceType><serviceId>urn:upnp-org:serviceId:dail</serviceId><controlURL>/ssdp/notfound</controlURL><eventSubURL>/ssdp/notfound</eventSubURL><SCPDURL>/ssdp/notfound</SCPDURL></service></serviceList></device></root>"
        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)

        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])
    }
    
    func test02_XMLData_OK () {
        
        // Manufacturer 02 regular device description
        
        testId = 2
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>    <friendlyName>friendly name 02</friendlyName>    <manufacturer>Manufacturer 02</manufacturer>    <modelName>Model Name 02</modelName>    <UDN>device ID 02</UDN>  </device></root>"
        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])
    }
    
    func test03_XMLData_WrongKeyword () {
        
        testId = 3
        
        // "version" keyword is mispelled ("verson")
        
        let xmlData = "<?xml verson=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>    <friendlyName> friendly name 02</friendlyName>    <manufacturer>Manufacturer 02</manufacturer>    <modelName>Model Name 02</modelName>    <UDN>device ID 02</UDN>  </device></root>"
        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])

    }
    
    func test04_XMLData_MissingMandatoryParameter01() {
        
        testId = 4
        
        // Required paramter is missing (friendlyName)
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>      <manufacturer>Manufacturer 02</manufacturer>    <modelName>Model Name 02</modelName>    <UDN>device ID 02</UDN>  </device></root>"
        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])

    }
    
    func test05_XMLData_MissingMandatoryParameter02 () {
        
        // 2 Required parameters missing (friendlyNamne and UDN)
        
        testId = 5
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>      <manufacturer>Manufacturer 02</manufacturer>    <modelName>Model Name 02</modelName>      </device></root>"
        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])

    }
    
    func test06_XMLData_MissingOptionalParameter () {
        
        // Optional parameter is missing (modelName)
        
        testId = 6
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>    <friendlyName>friendly name 02</friendlyName>  <manufacturer>Manufacturer 02</manufacturer>     <UDN>device ID 02</UDN>  </device></root>"

        
        let parserHelper = XMLHelper(for: "http://192.168.1.40:8088")
        let key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])
    }
    
    func test07_XMLData_MultipleResponses () {
        
        testId = 7
        
        // Got 2 answers to a MSEARCH: First Manufacturer 01, then Manufacturer 02
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root xmlns=\"urn:schemas-upnp-org:device-1-0\" xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\"><specVersion><major>1</major><minor>0</minor></specVersion><URLBase>http://192.168.1.33:56789</URLBase><device><deviceType>urn:schemas-upnp-org:device:dail:1</deviceType><friendlyName>friendly name 01</friendlyName><manufacturer>Manufacurer 01</manufacturer><modelName>Model Name 01</modelName><UDN>device ID 01</UDN><serviceList><service><serviceType>urn:schemas-upnp-org:service:dail:1</serviceType><serviceId>urn:upnp-org:serviceId:dail</serviceId><controlURL>/ssdp/notfound</controlURL><eventSubURL>/ssdp/notfound</eventSubURL><SCPDURL>/ssdp/notfound</SCPDURL></service></serviceList></device></root>"
        var parserHelper = XMLHelper (for: "http://192.168.1.40:8088")
        var key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        var key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        var key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        var key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])
        
        let xmlData2 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root  xmlns=\"urn:schemas-upnp-org:device-1-0\"  xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\">  <specVersion>    <major>1</major>    <minor>0</minor>  </specVersion>  <device>    <deviceType>urn:schemas-upnp-org:device:tvdevice:1</deviceType>    <friendlyName>friendly name 02</friendlyName>    <manufacturer>Manufacturer 02</manufacturer>    <modelName>Model Name 02</modelName>    <UDN>device ID 02</UDN>  </device></root>"
        
        parserHelper = XMLHelper(for: "http://192.168.1.41:8088")
        key1 = XMLHelper.KeyDefinition (name: "friendlyName", isMandatory: true)
        key2 = XMLHelper.KeyDefinition (name: "manufacturer", isMandatory: true)
        key3 = XMLHelper.KeyDefinition (name: "UDN", isMandatory: true)
        key4 = XMLHelper.KeyDefinition (name: "modelName", isMandatory: false)
        
        parserHelper.parseDocument(data: xmlData2.data(using: .utf8)!, withKeyList: [key1, key2, key3, key4])

    }
    
    func test08_XMLAdditionalData_OK () {
        
        testId = 8
        
        let xmlData = "<service xmlns=\"urn:dial-multiscreen-org:schemas:dial\" xmlns:ocast=\"urn:cast-ocast-org:service:cast:1\" dialVer=\"2.1\"> <name>APPID</name> <options allowStop=\"false\"/> <state>running</state> <additionalData><ocast:X_OCAST_App2AppURL>ws://192.168.1.40:4434/ocast</ocast:X_OCAST_App2AppURL> <ocast:X_OCAST_Version>1.0</ocast:X_OCAST_Version ></additionalData><link rel=\"run\" href=\"http://192.168.1.1\"/></service>"
        
        let parserHelper = XMLHelper (for: "http://192.168.1.40:8088")

        let key1 = XMLHelper.KeyDefinition (name: "ocast:X_OCAST_App2AppURL", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition (name: "ocast:X_OCAST_Version", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition (name: "link", isMandatory: true)
        
        parserHelper.parseDocument(data: xmlData.data(using: .utf8)!, withKeyList: [key1, key2, key3])
    }
    
    func didEndParsing(for application: String, result: [String : String], attributes: [String : [String : String]]) {
    
        let friendlyName = result["friendlyName"]
        let manufacturer = result["manufacturer"]
        let modelName = result["modelName"]
        let deviceID = result["UDN"]
        
        switch testId {
        case 1:
            XCTAssertTrue(application == "http://192.168.1.40:8088")
            XCTAssert(friendlyName == "friendly name 01")
            XCTAssert(manufacturer == "Manufacurer 01")
            XCTAssert(modelName == "Model Name 01")
            XCTAssert(deviceID == "device ID 01")
            
            
        case 2:
            XCTAssertTrue(application == "http://192.168.1.40:8088")
            XCTAssert(friendlyName == "friendly name 02")
            XCTAssert(manufacturer == "Manufacturer 02")
            XCTAssert(modelName == "Model Name 02")
            XCTAssert(deviceID == "device ID 02")
            
        case 6:
            XCTAssertTrue(application == "http://192.168.1.40:8088")
            XCTAssert(friendlyName == "friendly name 02")
            XCTAssert(manufacturer == "Manufacturer 02")
            XCTAssert(modelName == nil)
            XCTAssert(deviceID == "device ID 02")
            
        case 7:
            
            switch application {
                
            case "http://192.168.1.40:8088":
                XCTAssert(friendlyName == "friendly name 01")
                XCTAssert(manufacturer == "Manufacurer 01")
                XCTAssert(modelName == "Model Name 01")
                XCTAssert(deviceID == "device ID 01")
                
            case "http://192.168.1.41:8088":
                XCTAssert(friendlyName == "friendly name 02")
                XCTAssert(manufacturer == "Manufacturer 02")
                XCTAssert(modelName == "Model Name 02")
                XCTAssert(deviceID == "device ID 02")
            default:
                XCTAssert(false)
            }
            
        case 8:

            let app2URL = result ["ocast:X_OCAST_App2AppURL"]
            let version = result ["ocast:X_OCAST_Version"]
            let linkAttributes = attributes["link"]
            let rel = linkAttributes!["rel"]
            let href = linkAttributes!["href"]

            XCTAssert(app2URL == "ws://192.168.1.40:4434/ocast")
            
            XCTAssert(version == "1.0")
            XCTAssert(rel == "run")
            XCTAssert(href == "http://192.168.1.1")
            
        default:
            XCTAssert(false)
        }
    }
    
    func didParseWithError(for application: String, with error: Error, diagnostic: [String]) {
        switch testId {
        case 3:
            XCTAssertTrue(true)
        case 4:
            XCTAssertTrue(diagnostic == ["friendlyName"])
        case 5:
            XCTAssertTrue(diagnostic == ["friendlyName", "UDN"])
    
        default:
            XCTAssert(false)
        }
    }
}
