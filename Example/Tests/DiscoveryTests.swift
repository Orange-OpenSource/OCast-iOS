//
// DiscoveryTests.swift
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

class DummyDiscovery : DeviceDiscoveryDelegate {
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevice device: Device) {}
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevice device: Device) {}
    func deviceDiscoveryDidDisconnect(_ deviceDiscovery: DeviceDiscovery, withError error: Error?) {}
}

class DiscoveryTests: XCTestCase, DeviceDiscoveryDelegate {
    
    let searchTarget01 = "urn:vucast-manufacturer-01-org:service:vucast:1"
    let searchTarget02 = "urn:vucast-manufacturer-02-org:service:vucast:1"
    var deviceDiscovery : DeviceDiscovery!
    var deviceDiscovery02 : DeviceDiscovery!
    
    var testIdx = 0
    
    override func setUp() {
        super.setUp()
      
        deviceDiscovery = DeviceDiscovery(forTargets: [searchTarget01, searchTarget02])
        deviceDiscovery02 = DeviceDiscovery(forTargets: [searchTarget01, searchTarget02])
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test01ApplicationURL  () {
        
        // Application URL comes in Application-URL
        
        let appURL  = URL (string: "https://192.168.1.93:4433/")
        let headerFields = ["Content-Type" : "application/xml", "Content-Length" : "472", "Application-URL" : appURL!.absoluteString]
        let url = URL(string: "http://192.168.1.93/dd.xml")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        
        let applicationURL = deviceDiscovery.getApplicationURL(from: httpResponse)
        
        XCTAssert(applicationURL == appURL?.absoluteString)
    }
    
    func test02ApplicationURLIgnored () {
        
        // Application URL comes in Application-DIAL-URL (Application-URL must be ignored)
        
        let appURL  = URL (string: "https://192.168.1.93:4433/")
        let appDialURL = URL (string: "http://192.168.1.93:8008/apps")
        let headerFields = ["Content-Type" : "application/xml", "Content-Length" : "472", "Application-URL" : appURL!.absoluteString,"Application-DIAL-URL" : appDialURL!.absoluteString]
        let url = URL(string: "http://192.168.1.93/dd.xml")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        
        let applicationURL = deviceDiscovery.getApplicationURL(from: httpResponse)
        
        XCTAssertEqual(applicationURL, appDialURL?.absoluteString)
    }
    
    func test03ApplicationURLShouldBeEmpty  () {
        
        // Application URL must be ""
        let headerFields = ["Content-Type" : "application/xml", "Content-Length" : "472"]
        let url = URL(string: "http://192.168.1.93/dd.xml")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        
        if let _ = deviceDiscovery.getApplicationURL(from: httpResponse) {
            XCTFail()
            return
        }
    }
    
    func test04LocationPresent () {
        
        let searchResponse = "HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.48/dd.xml\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nST: urn:vucast-manufacturer-00-org:service:vucast:1\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
        
        if let location = deviceDiscovery.getStickLocation(fromUDPData: searchResponse) {
            XCTAssert(location == "http://192.168.1.48/dd.xml")
        } else {
            XCTFail()
        }
    }
    
    func test05LocationMissing () {
        
        let searchResponse = "HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nST: urn:vucast-manufacturer-00-org:service:vucast:1\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
        
        guard let _ = deviceDiscovery.getStickLocation(fromUDPData: searchResponse) else {
            return
        }
        
        XCTFail()
    }
    
    func test06SearchTargetPresent () {
        
        let searchResponse = "HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.48/dd.xml\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nST: urn:vucast-manufacturer-00-org:service:vucast:1\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
        let searchTarget = deviceDiscovery.getStickSearchTarget(fromUDPData: searchResponse)
        
        XCTAssertEqual(searchTarget, "vucast-manufacturer-00-org:service:vucast:1")
    }
    
    func test07SearchTargetMissing () {
        
        let searchResponse = "HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.48/dd.xml\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
        
        guard let _ = deviceDiscovery.getStickSearchTarget(fromUDPData: searchResponse) else {
            return
        }
        
        XCTFail()
    }
    
    func test08TargetMatchOK () {
        let searchResponse = "HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.48/dd.xml\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nST: urn:vucast-manufacturer-01-org:service:vucast:1\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
        
        if let searchTarget = deviceDiscovery.getStickSearchTarget(fromUDPData: searchResponse) {
            XCTAssert(deviceDiscovery.isTargetMatching(for: searchTarget))
        } else {
            XCTFail()
        }
    }
    
    func test09TargetMatchNOK () {
        let searchResponse = "HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.48/dd.xml\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nBOOTID.UPNP.ORG: 1\r\nSERVER: Linux/2.6 UPnP/1.0 quick_ssdp/1.0\r\nST: someTarget\r\nUSN: uuid:c4323fee-db4b-4227-9039-fa4b71589e26::\r\n\r\n"
       
        if let searchTarget = deviceDiscovery.getStickSearchTarget(fromUDPData: searchResponse) {
            XCTAssert(!deviceDiscovery.isTargetMatching(for: searchTarget))
        }
    }
    
    func test10StartStop () {
        
        // deviceDiscovey has already been initialized, but not yet started.
        
        XCTAssert(!deviceDiscovery.isRunning)
        
        // Start
        XCTAssert (deviceDiscovery.start())
      
        XCTAssert(deviceDiscovery.isRunning)
        
        deviceDiscovery.stop()
        XCTAssert(!deviceDiscovery.isRunning)
        XCTAssert (deviceDiscovery.start())
        
        
        // A start() without a previuos stop() should be ignored => The ssdp socket must be unchanged
        XCTAssert (!deviceDiscovery.start())
    }
    
    func test11IPV6Format () {
        
        let appURL  = URL (string: "https:/3ffe:0104:0103:00a0:0a00:20ff:fe0a:3ff7:4433/")
        let headerFields = ["Content-Type" : "application/xml", "Content-Length" : "472", "Application-URL" : appURL!.absoluteString]
        let url = URL(string: "http://3ffe:0104:0103:00a0:0a00:20ff:fe0a:3ff7/dd.xml")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        
        let applicationURL = deviceDiscovery.getApplicationURL(from: httpResponse)
        
        XCTAssert(applicationURL == appURL?.absoluteString)
    }

    func test12CreateDevice() {
        testIdx = 12
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root xmlns=\"urn:schemas-upnp-org:device-1-0\" xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\"><specVersion><major>1</major><minor>0</minor></specVersion><URLBase>http://192.168.1.33:56789</URLBase><device><deviceType>urn:schemas-upnp-org:device:dail:1</deviceType><friendlyName>Friendly Name 01</friendlyName><manufacturer>Manufacurer 01</manufacturer><modelName>Model Name 01</modelName><UDN>device ID 01</UDN><serviceList><service><serviceType>urn:schemas-upnp-org:service:dail:1</serviceType><serviceId>urn:upnp-org:serviceId:dail</serviceId><controlURL>/ssdp/notfound</controlURL><eventSubURL>/ssdp/notfound</eventSubURL><SCPDURL>/ssdp/notfound</SCPDURL></service></serviceList></device></root>"
        
        deviceDiscovery.createDevice(with: xmlData.data(using: String.Encoding.utf8)!, for: "http://192.168.1.33:56789")

    }
    
    func test15MultipleDiscoveryInstances () {
        
        testIdx = 15

        // These 2 DeviceDiscovery instances shall get the same device description
        
        XCTAssert (deviceDiscovery02.start())
        
        let xmlData = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root xmlns=\"urn:schemas-upnp-org:device-1-0\" xmlns:r=\"urn:restful-tv-org:schemas:upnp-dd\"><specVersion><major>1</major><minor>0</minor></specVersion><URLBase>http://192.168.1.33:56789</URLBase><device><deviceType>urn:schemas-upnp-org:device:dail:1</deviceType><friendlyName>Friendly Name 01</friendlyName><manufacturer>Manufacurer 01</manufacturer><modelName>Model Name 01</modelName><UDN>device ID 01</UDN><serviceList><service><serviceType>urn:schemas-upnp-org:service:dail:1</serviceType><serviceId>urn:upnp-org:serviceId:dail</serviceId><controlURL>/ssdp/notfound</controlURL><eventSubURL>/ssdp/notfound</eventSubURL><SCPDURL>/ssdp/notfound</SCPDURL></service></serviceList></device></root>"
        
        deviceDiscovery.createDevice(with: xmlData.data(using: String.Encoding.utf8)!, for: "http://192.168.1.33:56789")
        deviceDiscovery02.createDevice(with: xmlData.data(using: String.Encoding.utf8)!, for: "http://192.168.1.33:56789")
    }

    func testDevices () {
    
        XCTAssertTrue(deviceDiscovery.devices == [])
    }
    
    // Protocol functions
    
    func didEndParsing (for application: String, result: [String:String], attributes: [String : [String : String]]) {
        
        switch testIdx {
        case 12:
            XCTAssert(true)

        default:
            XCTAssert(false)
        }
    }
    

    func didParseWithError (for application: String, with error:Error, diagnostic: [String]) {
         XCTAssert(false)
    }

    // Protocol functions
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevice device: Device) {
        switch testIdx {
        case 12:
            if deviceDiscovery == self.deviceDiscovery {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
            
            break
        case 15:
            
            if deviceDiscovery == self.deviceDiscovery {
                XCTAssert(device.friendlyName == "Friendly Name 01")
                XCTAssert(device.manufacturer == "Manufacurer 01")
                XCTAssert(device.modelName == "Model Name 01")
                XCTAssert(device.deviceID == "device ID 01")
                testIdx = 151
            } else {
                XCTAssert(false)
            }
            
        case 151:
            
            if deviceDiscovery == self.deviceDiscovery02 {
                XCTAssert(device.friendlyName == "Friendly Name 01")
                XCTAssert(device.manufacturer == "Manufacurer 01")
                XCTAssert(device.modelName == "Model Name 01")
                XCTAssert(device.deviceID == "device ID 01")
            } else {
                XCTAssert(false)
            }
            
            
        default:
            XCTAssert(false)
        }
    }
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevice device: Device) {
        XCTFail()
    }
    
    func deviceDiscoveryDidDisconnect(_ deviceDiscovery: DeviceDiscovery, withError error: Error?) {}
}
