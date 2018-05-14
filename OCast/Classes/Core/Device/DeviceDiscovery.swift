//
// DeviceDiscovery.swift
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

import CocoaAsyncSocket

/**
 Provides information on device searching activity.
 */

@objc public protocol DeviceDiscoveryDelegate {
    /**
     Gets called when a new device is found.
     - Parameters:
         - deviceDiscovery: module (delegate) registered for notifications
         - device: added device information . See `Device` for details.
     */
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevice device: Device)

    /**
     Gets called when a device is lost.
     - Parameters:
         - deviceDiscovery: module (delegate) registered for notifications
         - device: lost device information . See `Device` for details.
     */
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevice device: Device)
}

/**
 Performs the device discovery activity.

 ```
 deviceDiscovery = DeviceDiscovery.init(for: self, forTargets: [ReferenceDriver.searchTarget])
 ```
 */
@objcMembers
@objc public class DeviceDiscovery: NSObject, GCDAsyncUdpSocketDelegate, HttpProtocol {

    // MARK: - Initialization

    /**
     Set the reliability level for the discovery process

     - `.high`: Sends a MSEARCH every 3s. If no anwser after 6s, device is considered as lost.
     - `.medium`: Sends a MSEARCH every 5s. If no anwser after 15s, device is considered as lost.
     - `.low`: Sends a MSEARCH every 10s. If no anwser after 50s, device is considered as lost.
     */
    
    @objc public enum Reliability: Int {
        case high
        case medium
        case low
    }
    
    enum ReliabilityParams {
        case high
        case medium
        case low
        
        var mSearchRetry: Int {
            switch self {
            case .high:
                return 2
            case .medium:
                return 3
            case .low:
                return 5
            }
        }
        
        var mSearchTimeout: TimeInterval {
            switch self {
            case .high:
                return 3
            case .medium:
                return 5
            case .low:
                return 10
            }
        }
    }

    public weak var delegate: DeviceDiscoveryDelegate?
    private let ssdpAddress = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    private var ssdpSocket: GCDAsyncUdpSocket?
    private var error: NSError?
    
    private var mSearchTargets: [String]
    private var mSearchTimer = Timer()
    private var mSearchTimeout: TimeInterval
    private var mSearchIdx: Int
    private var mSearchRetry: Int
    
    private var currentDevices = [String: Device]()
    private var currentDevicesIdx = [String: Int]()
    
    public private(set) var isRunning: Bool 
    
    /// List of current active devices
    public var devices: [Device] {
        return Array(currentDevices.values)
    }

    /**
     Initializes a new deviceDiscoevry class.
     - Parameters:
         - sender: module that will receive further notifications
         - searchTargets: list of device targets to search for
         - policy:  `Reliability` level for discovery process
     */

    @objc public init(forTargets searchTargets: Array<String>, withPolicy policy: DeviceDiscovery.Reliability) {
        mSearchIdx = 0
        self.mSearchTargets = searchTargets
        isRunning = false

        switch policy {
        case .high:
            mSearchTimeout = ReliabilityParams.high.mSearchTimeout
            mSearchRetry = ReliabilityParams.high.mSearchRetry
        case .medium:
            mSearchTimeout = ReliabilityParams.medium.mSearchTimeout
            mSearchRetry = ReliabilityParams.medium.mSearchRetry
        case .low:
            mSearchTimeout = ReliabilityParams.low.mSearchTimeout
            mSearchRetry = ReliabilityParams.low.mSearchRetry
        }

        OCastLog.debug("OCast SDK: Version 0.4.0")
    }

    /**
     Initializes a new deviceDiscoevry class. The `Reliability` level is set to `.high` by default (a MSEARCH is sent every 3s. If no anwser after 6s, the device is considered as lost).
     - Parameters:
         - sender: module that will receive further notifications
         - searchTargets: List of device targets to search for
     */
    public convenience init(forTargets searchTargets: Array<String>) {
        self.init(forTargets: searchTargets, withPolicy: DeviceDiscovery.Reliability.low)
    }

    // MARK: - DeviceDiscovery Interface

    /**
     Starts a discovery process.
     - Returns:
         - true if the discovery process could start.
         - false if the discovery process could not be started.
     */
    @discardableResult
    @objc public func start() -> Bool {

        guard !isRunning else {
            OCastLog.error("This instance is alreay running. Aborting.")
            return false
        }

        ssdpSocket?.close()

        ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)

        guard let ssdpSocket = ssdpSocket else {
            OCastLog.error("Could not create the UDP socket")
            return false
        }

        do {
            try ssdpSocket.bind(toPort: 0)
        } catch {
            OCastLog.error("Could not bind the UDP socket")
            ssdpSocket.close()
            return false
        }

        do {
            try ssdpSocket.beginReceiving()
        } catch {
            OCastLog.error("Could not setup the receiving call back")
            ssdpSocket.close()
            return false
        }

        resetContext()
        sendMSearch()
        mSearchTimer = Timer.scheduledTimer(timeInterval: mSearchTimeout, target: self, selector: #selector(mSearchTimerExpiry), userInfo: nil, repeats: true)

        isRunning = true

        return true
    }

    /**
     Stops a discovery process.
     */
    @objc public func stop() {
        ssdpSocket?.close()
        mSearchTimer.invalidate()
        isRunning = false
    }

    // MARK: - UDP management

    /// :nodoc:
    public func udpSocket(_ udpSocket : GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext _: Any?) {
        
        guard let udpData: NSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return
        }

        //OCastLog.debug("Ok From \(udpSocket.localHost() ?? "") on port \(udpSocket.localPort())\n\(udpData)")
 
        guard let searchTarget = getStickSearchTarget(fromUDPData: udpData as String) else {
            OCastLog.error("Search Target is missing or corrputed. Aborting.")
            return
        }

        if !isTargetMatching(for: searchTarget) {
            OCastLog.debug("Warning: Search Target is not as exepected \(searchTarget). Aborting.")
            return
        }

        guard let location = getStickLocation(fromUDPData: udpData as String) else {
            OCastLog.error("Location parameter is missing.")
            return
        }

        initiateHttpRequest(from: self, with: .get, to: location, onSuccess: didReceiveHttpResponse(response:with:), onError: { _ in })
    }

    /// :nodoc:
    public final func udpSocketDidClose(_: GCDAsyncUdpSocket, withError _: Error?) {
        OCastLog.debug("UDP Socket did close")
    }

    func sendMSearch() {
        if let ssdpSocket = ssdpSocket {
            var tagIndex = 0
            mSearchTargets.forEach { (target) in
                let mSearchString = "M-SEARCH * HTTP/1.1\r\nHOST: \(ssdpAddress):\(ssdpPort)\r\nMan: \"ssdp:discover\"\r\nMX:\(mSearchTimeout) \r\nST: \(target)\r\n\r\n"
            
                ssdpSocket.send(mSearchString.data(using: String.Encoding.utf8)!, toHost: ssdpAddress, port: ssdpPort, withTimeout: 1, tag: tagIndex)
                tagIndex += 1
            }
        }

        if mSearchIdx == type(of: mSearchIdx).max {
            OCastLog.debug("mSearchIdx reached the maximum allowed value.")
            currentDevicesIdx.keys.forEach({
                currentDevicesIdx[$0] = 0
            })
            mSearchIdx = 0
        }

        mSearchIdx += 1
    }

    // MARK: - Timer management

    @objc func mSearchTimerExpiry(timer _: Timer!) {

        currentDevices.forEach { (deviceId, cachedDevice) in
            if let deviceIdx = currentDevicesIdx[deviceId] {
                
                if deviceIdx + self.mSearchRetry <= mSearchIdx {
                    OCastLog.debug("Lost device \(cachedDevice.friendlyName)")
                    
                    currentDevices.removeValue(forKey: deviceId)
                    currentDevicesIdx.removeValue(forKey: deviceId)

                    delegate?.deviceDiscovery(self, didRemoveDevice: cachedDevice)
                }
            }
        }
        sendMSearch()
    }

    // MARK: - HTTP requests management

    func didReceiveHttpResponse(response: HTTPURLResponse, with data: Data?) {

        guard let data = data else {
            OCastLog.error("No data in Http Response.")
            return
        }

        createDevice(with: data, for: getApplicationURL(from: response))
    }

    func getApplicationURL(from httpResponse: HTTPURLResponse?) -> String? {

        let applicationDIALURL = httpResponse?.allHeaderFields["Application-DIAL-URL"]
        let applicationURL = httpResponse?.allHeaderFields["Application-URL"]
        OCastLog.debug("HTTP Response: DIAL-URL:\(applicationDIALURL ?? ""), URL:\(applicationURL ?? "")")

        if let appURL = applicationDIALURL {
            return appURL as? String
        } else if let appURL = applicationURL {
            return appURL as? String
        }

        return nil
    }

    // MARK: - Device management
    func createDevice(with xmlData: Data, for applicationURL: String?) {
        let parserHelper = XMLHelper()
        parserHelper.completionHandler = {
            (error, keys, keysAttributes) in
            if error == nil {
                guard
                    let deviceID = keys?["UDN"],
                    let friendlyName = keys?["friendlyName"],
                    let manufacturer = keys?["manufacturer"] else {
                        OCastLog.error("Missing attribute for device : \(keys ?? [:]).")
                        return
                }
                let modelName = keys?["modelName"] ?? ""
                
                if !self.currentDevices.contains(where: { (id, _) -> Bool in
                    return id == deviceID
                }) {
                    guard let url = applicationURL,
                        let baseURL = URL(string: url),
                        let ipAddress = baseURL.host,
                        let ipPort = baseURL.port else {
                            OCastLog.error("URL for Application-(DIAL)URL is invalid (\(applicationURL ?? "")")
                            return
                    }
                    
                    let device = Device(baseURL: baseURL,
                                        ipAddress: ipAddress,
                                        servicePort: UInt16(ipPort),
                                        deviceID: deviceID,
                                        friendlyName: friendlyName,
                                        manufacturer: manufacturer,
                                        modelName: modelName)
                    
                    self.currentDevices[device.deviceID] = device
                    DispatchQueue.main.async {
                        self.delegate?.deviceDiscovery(self, didAddDevice: device)
                    }
                }
                self.currentDevicesIdx[deviceID] = self.mSearchIdx
            } else {
                OCastLog.error("Error while parsing XML.")
            }
        }
        parserHelper.parseDocument(data: xmlData)
    }

    // MARK: - Private Helpers
    func resetContext() {
        currentDevices.removeAll()
        currentDevicesIdx.removeAll()
    }

    func getStickSearchTarget(fromUDPData dataString: String) -> String? {
        let dataArray = dataString.components(separatedBy: "\r\n")

        let searchTargetArray = dataArray.filter { (element) -> Bool in
            return element.hasPrefix("ST:")
        }

        guard let searchTargetElement = searchTargetArray.first, let result = searchTargetElement.range(of: "urn:") else {
            return nil
        }

        return String(searchTargetElement[result.upperBound ..< (searchTargetElement.endIndex)])
    }

    func getStickLocation(fromUDPData dataString: String) -> String? {
        let dataArray = dataString.components(separatedBy: "\r\n")

        let locationArray = dataArray.filter { (element) -> Bool in
            return element.hasPrefix("LOCATION:")
        }

        guard let locationElement = locationArray.first, let result = locationElement.range(of: "http") else {
            return nil
        }

        return String(locationElement[result.lowerBound ..< locationElement.endIndex])
    }

    func isTargetMatching(for searchTarget: String) -> Bool {
        let targetMatch = mSearchTargets.filter { (item) -> Bool in
            return item.contains(searchTarget)
        }

        return !targetMatch.isEmpty
    }
}
