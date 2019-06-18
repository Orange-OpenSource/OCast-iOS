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

class ViewController: UIViewController, DeviceCenterDelegate {
    
    
    /// The object to discover the devices
    private let center = DeviceCenter()
    
    // device
    private var device: Device?
    
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
        center.registerDevice(ReferenceDevice.self, forManufacturer: OCastDemoManufacturerName)
        
        // Launch the discovery process
        center.delegate = self
        center.resumeDiscovery()
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
    
    // MARK: DeviceCenter methods
    func center(_ center: DeviceCenter, didAdd devices: [Device]) {
        // Only one device (the first found)
        guard let device = devices.first, self.device == nil else { return }
        
        self.device = device
        stickLabel.text = String(format: "Stick: %@", device.ipAddress)
        self.device?.applicationName = "OCastDemoApplicationName"
        self.device?.connect(SSLConfiguration(), completion: { error in
            self.actionButton.isEnabled = error == nil
        })
    }
    
    func center(_ center: DeviceCenter, didRemove devices: [Device]) {
        for device in devices {
            if device.ipAddress == self.device?.ipAddress {
                resetUI()
                self.device = nil
            }
        }
    }
    
    func centerDidStop(_ center: DeviceCenter, withError error: Error?) {}

}

