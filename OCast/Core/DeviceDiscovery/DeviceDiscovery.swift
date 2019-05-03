//
// DeviceDiscovery.swift
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

/// Protocol for responding to device discovery events.
@objc public protocol DeviceDiscoveryDelegate: class {
    
    /// Tells the delegate that new devices are found.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: The device discovery informing the delegate.
    ///   - devices: The new devices found.
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevices devices: [Device])
    
    /// Tells the delegate that devices are lost.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: The device discovery informing the delegate.
    ///   - devices: The devices lost.
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevices devices: [Device])
    
    /// Tells the delegate that the discovery is stopped. All the devices are removed.
    ///
    /// - Parameters:
    ///   - deviceDiscovery: The device discovery informing the delegate.
    ///   - error: The error if there's an issue, `nil` if the device discovery has been stopped normally.
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, withError error: Error?)
}

/// Class to manage the device discovery using the SSDP protocol.
@objcMembers
@objc public class DeviceDiscovery: NSObject, UDPSocketDelegate {
    
    /// The UDP socket.
    private var udpSocket: UDPSocketProtocol
    
    /// The UPNP service.
    private let upnpService: UPNPServiceProtocol
    
    /// The search targets used to find the devices.
    private let searchTargets: [String]
    
    /// The SSDP multicast address.
    private let ssdpMulticastAddress = "239.255.255.250"
    
    /// The SSDP multicast port.
    private let ssdpMulticastPort: UInt16 = 1900
    
    /// The max time value used in a M-SEARCH request.
    private let maxtime = 3
    
    /// The dictionary (device ID/ Date) to save the date of the last response received.
    private var ssdpLastSeenDevices = [String: Date]()
    
    /// The dictionary (device ID/ device) to save the devices discovered on the local network.
    private var discoveredDevices = [String: Device]()
    
    /// The timer to launch the M-SEARCH requests depending the `interval`.
    private var refreshTimer: Timer?
    
    /// The current tasks to remove devices.
    private var removeDevicesTasks = [DispatchWorkItem]()
    
    /// `true` if the discovery is paused, otherwise `false`
    private var paused = false
    
    /// `true` if the discovery is stopped, otherwise `false`
    private var stopped = true
    
    /// `true` if the discovery is running, otherwise `false`
    private var isRunning: Bool {
        return !stopped && !paused
    }
    
    // The delegate to receive the device discovery events.
    public weak var delegate: DeviceDiscoveryDelegate?
    
    /// The devices discovered on the network
    public var devices: [Device] {
        return Array(discoveredDevices.values)
    }
    
    /// The interval in seconds to refresh the devices. The minimum value is 5 seconds.
    public var interval: UInt16 = 30 {
        didSet {
            interval = max(interval, 5)
            
            cancelAllTasks()
            refresh()
        }
    }
    
    /// Initiliazes the device discovery with custom search targets.
    /// Newly-initialized discovery begin in a suspended state, so you need to call `resume` method to start the discovery.
    ///
    /// - Parameter searchTargets: The search targets used to discover the devices.
    @objc convenience public init(_ searchTargets: [String]) {
        self.init(searchTargets, udpSocket: UDPSocket(delegateQueue: DispatchQueue(label: "org.ocast.udpsocket")))
    }
    
    /// Initializes the device discovery with the OCast search target.
    /// Newly-initialized discovery begin in a suspended state, so you need to call `resume` method to start the discovery.
    @objc convenience override init() {
        self.init(["urn:cast-ocast-org:service:cast:1"])
    }
    
    /// Initiliazes the device discovery with custom search targets and a socket object.
    ///
    /// - Parameters:
    ///   - searchTargets: The search targets used to discover the devices.
    ///   - udpSocket: The socket used to discover devices.
    ///   - upnpService: The UPNPService used.
    internal init(_ searchTargets: [String], udpSocket: UDPSocketProtocol, upnpService: UPNPServiceProtocol = UPNPService()) {
        self.searchTargets = searchTargets
        self.udpSocket = udpSocket
        self.upnpService = upnpService
        
        super.init()
        
        self.udpSocket.delegate = self
    }
    
    // MARK: Public methods
    
    /// Resumes the discovery process.
    /// The `delegate` must be set before to be notified when the devices list is updated.
    ///
    /// - Returns: `true` if the discovery is correctly started, otherwise `false`.
    @discardableResult
    @objc public func resume() -> Bool {
        guard !isRunning else { return false }
        
        do {
            try udpSocket.open(port: 0)
            paused = false
            stopped = false
            refresh()
            
            return true
        } catch {
            return false
        }
    }
    
    /// Stops the discovery process. All the devices are removed.
    /// The delegate method `deviceDiscoveryDidStop` will be called.
    ///
    /// - Returns: `true` if the discovery is correctly stopped, otherwise `false`.
    @discardableResult
    @objc public func stop() -> Bool {
        guard !stopped else { return false }
        
        paused = false
        stopped = true
        close()
        
        return true
    }
    
    /// Pauses the discovery process. The devices are not removed.
    ///
    /// - Returns: `true` if the discovery is correctly paused, otherwise `false`.
    @discardableResult
    @objc public func pause() -> Bool {
        guard isRunning else { return false }
        
        paused = true
        stopped = false
        close()
        
        return true
    }
    
    // MARK: Private methods
    
    /// Cancels all remove devices tasks and the refresh timer.
    private func cancelAllTasks() {
        refreshTimer?.invalidate()
        removeDevicesTasks.forEach({ $0.cancel() })
    }
    
    /// Sends a M-SEARCH request and schedule a timer given the current `interval`
    private func refresh() {
        sendSSDPMSearchRequest()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(interval),
                                            target: self,
                                            selector: #selector(sendSSDPMSearchRequest),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    /// Closes the socket et clean the discovery
    private func close() {
        udpSocket.close()
        clean()
    }
    
    /// Cleans the discovery and launch methods to inform the delegate
    ///
    /// - Parameter error: The socket error, otherwise `nil`
    private func clean(with error: Error? = nil) {
        cancelAllTasks()
        
        // Don't remove the devices when the discovery is paused
        guard !paused else { return }
        
        delegate?.deviceDiscovery(self, didRemoveDevices: devices)
        
        discoveredDevices.removeAll()
        ssdpLastSeenDevices.removeAll()
        
        delegate?.deviceDiscoveryDidStop(self, withError: error)
    }
    
    /// Sends a M-SEARCH request for each `searchTargets`.
    @objc private func sendSSDPMSearchRequest() {
        let sentDate = Date()
        for searchTarget in searchTargets {
            let host = ssdpMulticastAddress + ":" + String(ssdpMulticastPort)
            guard let payload = SSDPMSearchRequest(host: host, maxTime: maxtime, searchTarget: searchTarget).data else { continue }
            for _ in 1...2 {
                udpSocket.send(payload: payload, toHost: ssdpMulticastAddress, onPort: ssdpMulticastPort)
            }
        }
        
        let task = DispatchWorkItem { self.removeDevices(notSeenAfter: sentDate) }
        removeDevicesTasks.append(task)
        // Add 1 second for the network round-trip time.
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxtime) + TimeInterval(1.0), execute: task)
    }
    
    /// Removes devices that not been seen after the `sentDate`.
    ///
    /// - Parameter sentDate: The last sent date to check if a payload has been received after this date.
    @objc func removeDevices(notSeenAfter sentDate: Date) {
        guard isRunning else { return }
        
        let outdatedDevices = discoveredDevices.filter({
            guard let lastSeenDate = ssdpLastSeenDevices[$0.key] else { return false }
            // A payload has been received in the meantime.
            return lastSeenDate < sentDate
        })
        
        if outdatedDevices.count > 0 {
            self.delegate?.deviceDiscovery(self, didRemoveDevices: Array(outdatedDevices.values))
            outdatedDevices.forEach { discoveredDevices.removeValue(forKey: $0.key) }
        }
    }
    
    /// Handles a M-SEARCH response to add a new device if necessary.
    ///
    /// - Parameter mSearchResponse: The M-SEARCH response to process.
    private func handle(_ mSearchResponse: SSDPMSearchResponse) {
        guard isRunning, let UUID = UPNPService.extractUUID(from: mSearchResponse.USN) else { return }
        
        ssdpLastSeenDevices[UUID] = Date()

        if discoveredDevices[UUID] == nil {
            upnpService.device(fromLocation: mSearchResponse.location) { result in
                switch result {
                case .success(let device):
                    // Recheck to prevent from adding twice the same device if 2 incoming requests are received quickly
                    // and if the discovery has been stopped.
                    if self.discoveredDevices[UUID] == nil && self.isRunning {
                        self.discoveredDevices[UUID] = device
                        self.delegate?.deviceDiscovery(self, didAddDevices: [device])
                    }
                case .failure(_): break
                }
            }
        }
    }
    
    // MARK: UDPSocketDelegate methods
    
    func udpSocket(_ udpSocket: UDPSocketProtocol, didReceive data: Data, fromHost host: String?) {
        guard let response = String(data: data, encoding: .utf8),
            let mSearchResponse = SSDPResponseParser().parse(response: response) else { return }
        
        // Update collections on the main thread to avoid safety issues.
        DispatchQueue.main.sync {
            handle(mSearchResponse)
        }
    }
    
    func udpSocketDidClose(_ udpSocket: UDPSocketProtocol, with error: Error?) {
        guard let error = error else { return }
        
        DispatchQueue.main.sync {
            self.clean(with: error)
        }
    }
}
