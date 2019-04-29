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

    /// Gets called when a new device is found.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: module (delegate) registered for notifications
    ///   - device: added device information . See `Device` for details.
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevice device: Device)

    /// Gets called when a device is lost.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: module (delegate) registered for notifications
    ///   - device: lost device information . See `Device` for details.
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevice device: Device)
    
    /// Gets called when the discovery is stopped by error or not. All the devices are removed.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: module (delegate) registered for notifications
    ///   - error: the error if there's a problem, nil if the `DeviceDiscovery` has been stopped normally.
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, withError error: Error?)
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
    private var ssdpSocket: GCDAsyncUdpSocket
    private var error: NSError?
    
    private var mSearchTargets: [String]
    private var mSearchTimer = Timer()
    private var mSearchTimeout: TimeInterval
    private var mSearchIdx: Int
    private var mSearchRetry: Int
    private let regularExpression = try? NSRegularExpression(pattern: "^uuid:([^:]*)")
    
    private var currentDevices = [String: Device]()
    private var currentDevicesIdx = [String: Int]()
    
    /// List of current active devices
    public var devices: [Device] {
        return Array(currentDevices.values)
    }

    /// Initializes a new deviceDiscovery class.
    ///
    /// - Parameters:
    ///   - searchTargets: list of device targets to search for
    ///   - policy: `Reliability` level for discovery process
    @objc public init(forTargets searchTargets: Array<String>, withPolicy policy: DeviceDiscovery.Reliability) {
        ssdpSocket = GCDAsyncUdpSocket()
        mSearchIdx = 0
        self.mSearchTargets = searchTargets
        
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
        
        super.init()
        
        ssdpSocket.setDelegate(self)
        ssdpSocket.setDelegateQueue(DispatchQueue.main)
    }
    
    /// Initializes a new deviceDiscovery class. The `Reliability` level is set to `.high` by default (a MSEARCH is sent every 3s. If no anwser after 6s, the device is considered as lost).
    ///
    /// - Parameter searchTargets: List of device targets to search for
    public convenience init(forTargets searchTargets: Array<String>) {
        self.init(forTargets: searchTargets, withPolicy: DeviceDiscovery.Reliability.low)
    }

    // MARK: - DeviceDiscovery Interface
    /// Starts a discovery process.
    ///
    /// - Returns: true if the discovery process could start, false if the discovery process could not be started.
    @discardableResult
    @objc public func start() -> Bool {
        guard !ssdpSocket.isConnected() else {
            OCastLog.error("This instance is alreay running. Aborting.")
            return false
        }
        
        do {
            try ssdpSocket.bind(toPort: 0)
            try ssdpSocket.beginReceiving()
        } catch {
            OCastLog.error("Cannot start the discovery")
            ssdpSocket.close()
            return false
        }

        resetContext()
        sendMSearch()
        mSearchTimer = Timer.scheduledTimer(timeInterval: mSearchTimeout, target: self, selector: #selector(mSearchTimerExpiry), userInfo: nil, repeats: true)

        return true
    }

    /// Stops a discovery process.
    @objc public func stop() {
        ssdpSocket.close()
    }

    // MARK: - UDP management
    /// :nodoc:
    public func udpSocket(_ udpSocket : GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext _: Any?) {
        guard let udpString = String(data: data, encoding: .utf8),
            let searchTarget = getStickSearchTarget(fromUDPData: udpString),
            isTargetMatching(for: searchTarget),
            let location = getStickLocation(fromUDPData: udpString) else {
                OCastLog.error("Bad SSDP response")
                return
        }
        
        initiateHttpRequest(with: .get,
                            to: location,
                            headers: ["Date": dateFormatter.string(from: Date())],
                            onSuccess: didReceiveHttpResponse(response:with:), onError: { _ in })
    }

    /// :nodoc:
    public final func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        mSearchTimer.invalidate()
        resetContext()
        
        delegate?.deviceDiscoveryDidStop(self, withError: error)
    }

    func sendMSearch() {
        var tagIndex = 0
        mSearchTargets.forEach { (target) in
            let mSearchString = "M-SEARCH * HTTP/1.1\r\nHOST: \(ssdpAddress):\(ssdpPort)\r\nMAN: \"ssdp:discover\"\r\nMX:\(mSearchTimeout) \r\nST: \(target)\r\n\r\n"
            
            ssdpSocket.send(mSearchString.data(using: .utf8)!, toHost: ssdpAddress, port: ssdpPort, withTimeout: 1, tag: tagIndex)
            tagIndex += 1
        }

        mSearchIdx += 1
    }

    // MARK: - Timer management

    @objc func mSearchTimerExpiry(timer _: Timer!) {

        currentDevices.forEach { (deviceId, cachedDevice) in
            if let deviceIdx = currentDevicesIdx[deviceId] {
                
                if deviceIdx + self.mSearchRetry <= mSearchIdx {
                    
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
        parserHelper.completionHandler = { error, keys, _ in
            if error == nil, let keys = keys {
                DispatchQueue.main.async {
                    self.createDevice(fromXMLKeys: keys, for: applicationURL)
                }
            }
        }
        parserHelper.parseDocument(data: xmlData)
    }
    
    /// Extracts the device unique ID from the UDN key.
    ///
    /// - Parameter UDN: The UDN key to parse.
    /// - Returns: The device unique ID.
    private func deviceID(from UDN: String) -> String? {
        guard let result = regularExpression?.firstMatch(in: UDN, options: [], range: NSRange(location: 0, length: UDN.count)),
            result.numberOfRanges == 2,
            let range = Range(result.range(at: 1), in: UDN) else { return nil }
        
        return String(UDN[range])
    }
    
    private func createDevice(fromXMLKeys keys: [String: String], for applicationURL: String?) {
        guard let UDN = keys["UDN"],
            let deviceID = deviceID(from: UDN),
            let friendlyName = keys["friendlyName"],
            let manufacturer = keys["manufacturer"],
            let modelName = keys["modelName"] else { return }
                
        let deviceAlreadyDiscovered = currentDevices.contains(where: { (id, _) -> Bool in return id == deviceID })
        
        if !deviceAlreadyDiscovered {
            guard let url = applicationURL,
                let baseURL = URL(string: url),
                let ipAddress = baseURL.host,
                let ipPort = baseURL.port else { return }
            
            let device = Device(baseURL: baseURL,
                                ipAddress: ipAddress,
                                servicePort: UInt16(ipPort),
                                deviceID: deviceID,
                                friendlyName: friendlyName,
                                manufacturer: manufacturer,
                                modelName: modelName)
            
            currentDevices[device.deviceID] = device
            delegate?.deviceDiscovery(self, didAddDevice: device)
        }
        
        currentDevicesIdx[deviceID] = mSearchIdx
    }

    // MARK: - Private Helpers
    
    /// The dateformatter to send the date header (RFC 7231)
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    
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
