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

extension OCastDevice: OCastDeviceProtocol {
    public static var manufacturer: String = "manufacturer"
    public static var searchTarget: String = "urn:cast-ocast-org:service:cast:1"
}

class ViewController: UIViewController, OCastDiscoveryDelegate {
    
    /// The object to discover the devices
    private let center = OCastCenter()
    
    // device
    private var device: OCastDeviceProtocol?
    
    /// Indicates whether a cast is in progress
    private var isCastInProgress: Bool = false
    
    /// IBOutlets
    @IBOutlet weak var stickLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: Overriden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetUI()
        
        // Register the driver
        center.registerDevice(OCastDevice.self)
        
        // Launch the discovery process
        center.discoveryDelegate = self
        center.startDiscovery()
    }
    
    // MARK: Private methods
    
    @IBAction func actionButtonClicked(_ sender: Any) {

        if !isCastInProgress {
            startCast()
        } else {
            stopCast()
        }
    }
    
    /// Starts the cast
    ///
    /// - Parameter mediaController: The `MediaController` used to cast.
    private func startCast() {
        isCastInProgress = true
        let command = MediaPrepareCommand(url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4", frequency: 1, title: "Movie Sample", subtitle: "Brought to you", logo: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/", mediaType: .video, transferMode: .buffered, autoPlay: true)
        
        device?.prepare(command, withOptions: nil, completion: { _ in
            
        })

    }

    private func stopCast() {
        isCastInProgress = false
        device?.stop(withOptions: nil, completion: { (error) in
            print(error ?? "no error")
        })
    }

    private func resetUI() {
        stickLabel.text = "Stick: -"
        actionButton.isEnabled = false
    }
    
    // MARK: DeviceDiscoveryDelegate methods
    func discovery(_ center: OCastCenter, didAddDevice device: OCastDeviceProtocol) {
        // Only one device (the first found)
        if self.device != nil {
            return
        }
        
        self.device = device
        stickLabel.text = String(format: "Stick: %@", device.ipAddress)
        self.device?.connect(SSLConfiguration(), completion: { error in
            self.actionButton.isEnabled = error == nil
        })
    }
    
    func discovery(_ center: OCastCenter, didRemoveDevice device: OCastDeviceProtocol) {
        if device.ipAddress == self.device?.ipAddress {
            resetUI()
            self.device = nil
        }
    }
    
    func discoveryDidStop(_ center: OCastCenter, withError error: Error?) {}

}

