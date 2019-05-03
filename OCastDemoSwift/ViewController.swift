//
// ViewController.swift
//
// Copyright 2018 Orange
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

import UIKit
import OCast

class ViewController: UIViewController, DeviceDiscoveryDelegate, DeviceManagerDelegate, MediaControllerDelegate {
    
    /// The object to discover the devices
    private let deviceDiscovery = DeviceDiscovery([ReferenceDriver.searchTarget])
    
    /// The `DeviceManager`
    private var deviceManager: DeviceManager?
    
    /// The `ApplicationController`
    private var applicationController: ApplicationController?
    
    /// The state to know if a cast is in progress
    private var playerState: PlayerState = .unknown
    
    /// Indicates whether a cast is in progress
    private var isCastInProgress: Bool {
        return playerState != .unknown && playerState != .idle
    }
    
    /// IBOutlets
    @IBOutlet weak var stickLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: Overriden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetUI()
        
        // Register the driver
        DeviceManager.registerDriver(ReferenceDriver.self, forManufacturer: OCastDemoDriverName)
        
        // Launch the discovery process
        deviceDiscovery.delegate = self
        deviceDiscovery.resume()
    }
    
    // MARK: Private methods
    
    @IBAction func actionButtonClicked(_ sender: Any) {
        guard let applicationController = applicationController else { return }
        
        if !isCastInProgress {
            startCast(applicationController.mediaController)
        } else {
            stopCast(applicationController.mediaController)
        }
    }
    
    /// Starts the cast
    ///
    /// - Parameter mediaController: The `MediaController` used to cast.
    private func startCast(_ mediaController: MediaController) {
        let mediaPrepapre = MediaPrepare(
            url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
            frequency : 1,
            title: "Movie sample",
            subtitle: "Brought to you by Orange OCast",
            logo: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/")!,
            mediaType: .video,
            transferMode: .buffered,
            autoplay: true)
        
        mediaController.prepare(for: mediaPrepapre,
                                onSuccess: {},
                                onError: { _ in })
    }
    
    /// Stops the cast
    ///
    /// - Parameter mediaController: The `MediaController` used to stop the cast.
    private func stopCast(_ mediaController: MediaController) {
        mediaController.stop(onSuccess: {},
                             onError: { _ in })
    }
    
    /// Resets the UI
    private func resetUI() {
        stickLabel.text = "Stick: -"
        actionButton.isEnabled = false
    }
    
    /// Starts the application
    private func startApplication() {
        applicationController?.start(onSuccess: {
            DispatchQueue.main.async {
                self.actionButton.isEnabled = true
            }
        },
                                     onError: { _ in
                                        DispatchQueue.main.async {
                                            self.actionButton.isEnabled = false
                                        }
        })
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didAddDevices devices: [Device]) {
        // Only one device (the first found)
        guard deviceManager == nil, let device = devices.first else { return }
        
        // Create the device manager
        deviceManager = DeviceManager(with: device, sslConfiguration: nil)
        deviceManager?.delegate = self
        
        stickLabel.text = String(format: "Stick: %@", device.friendlyName)
        
        // Retrieve the applicationController
        deviceManager?.applicationController(for: OCastDemoApplicationName,
                                             onSuccess: { applicationController in
                                                applicationController.mediaController.delegate = self
                                                self.applicationController = applicationController
                                                self.startApplication()
        },
                                             onError: { _ in })
    }
    
    func deviceDiscovery(_ deviceDiscovery: DeviceDiscovery, didRemoveDevices devices: [Device]) {
        guard let device = devices.first else { return }
        
        if deviceManager?.device == device {
            deviceManager = nil
            resetUI()
        }
    }
    
    func deviceDiscoveryDidStop(_ deviceDiscovery: DeviceDiscovery, withError error: Error?) {}
    
    // MARK: DeviceManagerDelegate methods
    
    func deviceManager(_ deviceManager: DeviceManager, applicationDidDisconnectWithError error: NSError) {
        self.deviceManager = nil
        resetUI()
    }
    
    // MARK: MediaControllerDelegate methods
    
    func mediaController(_ mediaController: MediaController, didReceivePlaybackStatus playbackStatus: PlaybackStatus) {
        playerState = playbackStatus.state
        if isCastInProgress {
            actionButton.setTitle("Stop", for: [])
        } else {
            actionButton.setTitle("Play", for: [])
        }
    }
    
    func mediaController(_ mediaController: MediaController, didReceiveMetadata metadata: Metadata) {}
}

