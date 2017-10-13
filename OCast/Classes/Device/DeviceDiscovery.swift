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

@objc public protocol DeviceDiscoveryProtocol {
    /**
     Gets called when a new device is found.
     - Parameters:
     - deviceDiscovery: module (delegate) registered for notifications
     - device: added device information . See `Device` for details.
     */
    func onDeviceAdded(from deviceDiscovery: DeviceDiscovery, forDevice device: Device)

    /**
     Gets called when a device is lost.
     - Parameters:
     - deviceDiscovery: module (delegate) registered for notifications
     - device: lost device information . See `Device` for details.
     */
    func onDeviceRemoved(from deviceDiscovery: DeviceDiscovery, forDevice device: Device)
}

/**
 Performs the device discovery activity.

 ```
 deviceDiscovery = DeviceDiscovery.init(for: self, forTargets: [ReferenceDriver.searchTarget])
 ```
 */

@objc public class DeviceDiscovery: NSObject, GCDAsyncUdpSocketDelegate, XMLHelperProtocol, HttpProtocol {

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

    /**
     Initializes a new deviceDiscoevry class.
     - Parameters:
     - sender: module that will receive further notifications
     - mSearchTargets: List of device targets to search for
     - policy:  `Reliability` level for discovery process
     */

    @objc public init(for sender: Any, forTargets mSearchTargets: Array<String>, withPolicy policy: DeviceDiscovery.Reliability) {

        delegates.append(sender as? DeviceDiscoveryProtocol)
        mSearchIdx = 0
        self.mSearchTargets = mSearchTargets
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

        print("OCast SDK: Version 0.1.0")
    }

    /**
     Initializes a new deviceDiscoevry class. The `Reliability` level is set to `.high` by default (a MSEARCH is sent every 3s. If no anwser after 6s, the device is considered as lost).
     - Parameters:
     - sender: module that will receive further notifications
     - mSearchTargets: List of device targets to search for
     */
    public convenience init(for sender: DeviceDiscoveryProtocol, forTargets searchTargets: Array<String>) {
        self.init(for: sender, forTargets: searchTargets, withPolicy: DeviceDiscovery.Reliability.high)
    }

    // MARK: - DeviceDiscovery Interface

    /// List of current active devices

    public var devices: [Device] {
        return currentDevices.map { (_, device) -> Device in
            device
        }
    }

    /**
     Starts a discovery process.
     - Returns:
     - true if the discovery process could start.
     - false if the discovery process could not be started.
     */

    public func start() -> Bool {

        guard !isRunning else {
            OCastLog.error("This instance is alreay running. Aborting.")
            return false
        }

        if let socket = ssdpSocket {
            socket.close()
        }

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

    public func stop() {

        if let ssdpSocket = self.ssdpSocket {
            ssdpSocket.close()
        }

        mSearchTimer.invalidate()
        isRunning = false
    }

    /**
     - Returns:
     - true if the discovery process is started.
     - false if the discovery process is not started.
     */

    public func isStarted() -> Bool {
        return isRunning
    }

    // MARK: - UDP management

    /// :nodoc:
    public func udpSocket(_: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext _: Any?) {
        var host: NSString?
        var port: UInt16 = 0

        GCDAsyncUdpSocket.getHost(&host, port: &port, fromAddress: address as Data)

        let udpData: NSString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)!
        OCastLog.debug("\n >> From \(host!) on port \(port)\n\(udpData)")

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

    /*--------------------------------------------------------------------------------------------------------------------------------------*/

    // MARK: - Internal

    var delegates: [DeviceDiscoveryProtocol?] = []
    let ssdpAddres = "239.255.255.250"
    let ssdpPort: UInt16 = 1900
    var ssdpSocket: GCDAsyncUdpSocket?
    var error: NSError?

    var mSearchTargets: [String]
    var mSearchTimer = Timer()
    var mSearchTimeout: TimeInterval
    var mSearchIdx: Int
    var mSearchRetry: Int

    var currentDevices = [String: Device]()
    var currentDevicesIdx = [String: Int]()

    var isRunning: Bool

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

    func sendMSearch() {

        var tagIndex = 0

        _ = mSearchTargets.map { (searchTarget) -> Void in

            let mSearchString = "M-SEARCH * HTTP/1.1\r\nHOST: \(ssdpAddres):\(ssdpPort)\r\nMan: \"ssdp:discover\"\r\nMX:\(mSearchTimeout) \r\nST: \(searchTarget)\r\n\r\n"

            guard let ssdpSocket = ssdpSocket else {
                return
            }

            ssdpSocket.send(mSearchString.data(using: String.Encoding.utf8)!, toHost: ssdpAddres, port: ssdpPort, withTimeout: 1, tag: tagIndex)
            tagIndex += 1
        }

        if mSearchIdx == type(of: mSearchIdx).max {

            OCastLog.debug("mSearchIdx reached the maximum allowed value.")

            _ = currentDevicesIdx.map { (idxFromList, _) -> Void in
                currentDevicesIdx[idxFromList] = 0
                return
            }

            mSearchIdx = 0
        }

        mSearchIdx += 1
    }

    // MARK: - Timer management

    func mSearchTimerExpiry(timer _: Timer!) {

        _ = currentDevices.map { (deviceId, cachedDevice) -> Void in

            if let deviceIdx = currentDevicesIdx[deviceId] {

                if deviceIdx + self.mSearchRetry <= mSearchIdx {
                    OCastLog.debug("Lost device \(cachedDevice.friendlyName)")

                    currentDevices.removeValue(forKey: deviceId)
                    currentDevicesIdx.removeValue(forKey: deviceId)

                    for delegate in self.delegates {
                        delegate?.onDeviceRemoved(from: self, forDevice: cachedDevice)
                    }
                }
            }
        }

        OCastLog.debug("Resending MSEARCH")
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

        OCastLog.debug("HTTP Response: \(String(describing: httpResponse!))")

        if let applicationURL = httpResponse?.allHeaderFields["Application-DIAL-URL"] {
            return applicationURL as? String
        } else {

            if let applicationURL = httpResponse?.allHeaderFields["Application-URL"] {
                return applicationURL as? String
            }
        }

        return nil
    }

    // MARK: - Device management

    func createDevice(with xmlData: Data, for applicationURL: String?) {

        guard let applicationURL = applicationURL else {
            OCastLog.error("Application URL is empty.)")
            return
        }

        let parserHelper = XMLHelper(fromSender: self, for: applicationURL)

        let key1 = XMLHelper.KeyDefinition(name: "friendlyName", isMandatory: true)
        let key2 = XMLHelper.KeyDefinition(name: "manufacturer", isMandatory: true)
        let key3 = XMLHelper.KeyDefinition(name: "UDN", isMandatory: true)
        let key4 = XMLHelper.KeyDefinition(name: "modelName", isMandatory: false)

        parserHelper.parseDocument(data: xmlData, withKeyList: [key1, key2, key3, key4])
    }

    // MARK: - XML management

    func didEndParsing(for application: String, result: [String: String], attributes _: [String: [String: String]]) {

        DispatchQueue.main.async {

            let deviceID = result["UDN"]!
            let friendlyName = result["friendlyName"]!
            let manufacturer = result["manufacturer"]!
            let modelName = result["modelName"]

            let duplicateDevices = self.currentDevices.filter { (deviceIDFromList, _) -> Bool in
                return deviceID == deviceIDFromList
            }

            if duplicateDevices.isEmpty {

                let baseURL = URL(string: application)!

                guard let ipAddress = baseURL.host else {
                    OCastLog.error("IP address for Application-(DIAL)URL is empty.)")
                    return
                }

                guard let ipPort = baseURL.port else {
                    OCastLog.error("Port for Application-(DIAL)URL is empty.)")
                    return
                }

                let device = Device(baseURL: baseURL,
                                    ipAddress: ipAddress,
                                    servicePort: UInt16(ipPort),
                                    deviceID: deviceID,
                                    friendlyName: friendlyName,
                                    manufacturer: manufacturer,
                                    modelName: modelName ?? "")

                self.currentDevices[device.deviceID] = device
                self.currentDevicesIdx[device.deviceID] = self.mSearchIdx

                for delegate in self.delegates {
                    delegate?.onDeviceAdded(from: self, forDevice: device)
                }

                OCastLog.debug("Adding a new device (\(device.friendlyName)). Have now \(self.currentDevices.count) cached device(s).")

            } else {

                self.currentDevicesIdx[deviceID] = self.mSearchIdx
                OCastLog.debug("\(friendlyName) is already inserted. Have now \(self.currentDevices.count) cached device(s).")
            }
        }
    }

    func didParseWithError(for _: String, with error: Error, diagnostic: [String]) {
        OCastLog.error("DeviceDiscovery: Parsing failed with error = \(error). Diagnostic: \(diagnostic)")
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

        guard let searchTargetElement = searchTargetArray.first else {
            return nil
        }

        guard let result = searchTargetElement.range(of: "urn:") else {
            return nil
        }

        return searchTargetElement[result.upperBound ..< (searchTargetElement.endIndex)]
    }

    func getStickLocation(fromUDPData dataString: String) -> String? {
        let dataArray = dataString.components(separatedBy: "\r\n")

        let locationArray = dataArray.filter { (element) -> Bool in
            return element.hasPrefix("LOCATION:")
        }

        guard let locationElement = locationArray.first else {
            return nil
        }

        guard let result = locationElement.range(of: "http") else {
            return nil
        }

        return locationElement[result.lowerBound ..< locationElement.endIndex]
    }

    func isTargetMatching(for searchTarget: String) -> Bool {
        let targetMatch = mSearchTargets.filter { (item) -> Bool in
            return item.contains(searchTarget)
        }

        return !targetMatch.isEmpty
    }
}
