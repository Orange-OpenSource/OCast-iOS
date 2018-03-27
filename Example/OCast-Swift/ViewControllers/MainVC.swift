//
// ViewController.swift
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

import UIKit
import OCast

class MainVC: UIViewController, DeviceDiscoveryProtocol, MediaControllerDelegate, DeviceManagerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet var webAppLabel: UITextField!
    @IBOutlet var webAppStatusLabel: UILabel!
    @IBOutlet var positionLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var playerStateLabel: UILabel!
    @IBOutlet var customAnswerLabel: UILabel!
    
    @IBOutlet var stickPickerView: UIPickerView!
    
    @IBOutlet var errorMessageLabel: UILabel!
    @IBOutlet var volumeLabel: UILabel!
    @IBOutlet var muteButton: UIButton!
    @IBOutlet var errorSettingLabel: UILabel!
    @IBOutlet var stickStatusLabel: UILabel!
    @IBOutlet var connectedButton: UIBarButtonItem!
    @IBOutlet var playbackPosition: UILabel!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var stickNameLabel: UILabel!

    @IBOutlet var seekSlider: UISlider!
    @IBOutlet var metadataTitleLabel: UILabel!
    
    @IBOutlet var pictureLabel: UILabel!
    @IBOutlet var textTrackButton: UIButton!
    @IBOutlet var videoTrackButton: UIButton!
    @IBOutlet var audioTrackButton: UIButton!
    @IBOutlet var textTrackLabel: UILabel!
    @IBOutlet var videoTrackLabel: UILabel!
    @IBOutlet var audioTrackLabel: UILabel!
    
    let referenceST = ReferenceDriver.searchTarget
    var deviceDiscovery: DeviceDiscovery!
    var deviceMgr: DeviceManager?
    var appliMgr: ApplicationController?

    var customStream : CustomStream?
    var mediaController: MediaController?
    var shouldPause: Bool = true
    var shouldMute: Bool = true
    var mediaDuration: Double = 0.0

    var audioTracks: [TrackDescription] = []
    var videoTracks: [TrackDescription] = []
    var textTracks: [TrackDescription] = []
    var currentAudioIdx: Int = 0
    var currentVideoIdx: Int = 0
    var currentTextIdx: Int = 0
    
    var devices: [Device] = []
   
    var applicationName =  "Orange-OrangeTVReceiverDev-SDK2018" // Orange-DefaultReceiver-DEV"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI ()

        if !DeviceManager.registerDriver(forName: ReferenceDriver.manufacturer, factory: ReferenceDriverFactory.sharedInstance) {
            return
        }
        
        deviceDiscovery = DeviceDiscovery.init(for: self, forTargets: [referenceST])

        guard deviceDiscovery.start() else {
            return
        }
        
        
    }

    
    //MARK: DeviceManager protocol
    
    func onFailure(error: NSError) {
        OCastLog.debug("-> Connection to the stick is down.")

        resetContext ()
       
        guard deviceDiscovery.start() else {
            return
        }
        
        devices = deviceDiscovery.devices
        stickPickerView.reloadAllComponents()
    }
    
    // MARK: - Device Discovery protocol
    
    func onDeviceAdded(from deviceDiscovery: DeviceDiscovery, forDevice device: Device) {

        devices = deviceDiscovery.devices
        
        if deviceDiscovery == deviceDiscovery {
            OCastLog.debug("-> Device added = \(device.friendlyName). Now managing \(devices.count) device(s).")
        }

        stickPickerView.reloadAllComponents()
    }
    
    func onDeviceRemoved(from deviceDiscovery: DeviceDiscovery, forDevice device: Device) {
        devices = deviceDiscovery.devices
        stickPickerView.reloadAllComponents()
        
        if devices.count == 0 {
           setupUI()
        }

        OCastLog.debug ("-> Device lost = \(device.friendlyName). Now managing \(devices.count) device(s).")
        
        
    }
    
    func onDeviceSelected(device: Device) {
        
        stickNameLabel.text = device.friendlyName
        setUIStickSelected ()
        
        createDeviceManager(with: device)
    }
    

    
    //MARK: - WebApp control
    
    @IBAction func onStart(_ sender: Any) {
        
        webAppStatusLabel.text = "Start-Pending"
        errorMessageLabel.text = ""

        setupWebAppCtx (onSuccess: startApplication,
                        onError: { error in
                            DispatchQueue.main.async {
                                self.webAppStatusLabel.text = "Start-NOK"
                                OCastLog.error("-> Web app failed to start.")
                            }
                        }
                    )
    }
    
    func startApplication () {
        
        appliMgr!.start (
            onSuccess: { 
                DispatchQueue.main.async {
                    self.deviceDiscovery.stop()
                    self.webAppStatusLabel.text = "Start-OK"
                    self.setUIWebAppConnected ()
                    OCastLog.debug(("-> Web App START is OK"))
                }
            },
                        
            onError: { error in
                DispatchQueue.main.async {
                                
                    self.webAppStatusLabel.text = "Start-NOK"
                                
                    if let error = error {
                        let key = error.userInfo.keys.first!
                        let info = error.userInfo[key] ?? ""
                        let errorMessage = "Code: \(error.code). \(info)"
                        self.errorMessageLabel.text = errorMessage
                    }
                                
                    OCastLog.error("-> Web app failed to start.")
                }
            }
        )
    }


    @IBAction func onJoin(_ sender: Any) {
        webAppStatusLabel.text = "Join-Pending"
        errorMessageLabel.text = ""
        
        setupWebAppCtx (
            onSuccess: joinApplication,
            onError: { error in
                            DispatchQueue.main.async {
                                self.webAppStatusLabel.text = "Join-NOK"
                                self.setUIWebAppConnected ()
                                OCastLog.error("-> Web app failed to join.")
                            }
                    }
        )

    }
    
    func joinApplication () {
        
        appliMgr!.join (
            onSuccess: { 
            
                DispatchQueue.main.async {
                    self.webAppStatusLabel.text = "Join-OK"
                    self.deviceDiscovery.stop()
                    OCastLog.debug("-> Web App JOIN is OK")}
                },
                       
                onError: { error in
                        
                    DispatchQueue.main.async {
                        self.webAppStatusLabel.text = "Join-NOK"
                            
                        if let error = error {
                            let key = error.userInfo.keys.first!
                            let info = error.userInfo[key] ?? ""
                            self.errorMessageLabel.text = info as? String
                        }
                            
                        OCastLog.error("-> Web app failed to join")
                    }
                }
        )
    }
    
    @IBAction func onStop(_ sender: Any) {
        
        guard let appliMgr = appliMgr else {
            return
        }
        
        self.webAppStatusLabel.text = "Stop-Pending"
        self.errorMessageLabel.text = ""
        
        appliMgr.stop(
            onSuccess: { 
            
                DispatchQueue.main.async {
                    OCastLog.debug(("-> Web App STOP is OK"))
                    self.webAppStatusLabel.text = "Stop-OK"
                    self.setUIWebAppDisconnected ()
                    
                    guard self.deviceDiscovery.start() else {
                        return
                    }
                    
                    self.devices = self.deviceDiscovery.devices
                    self.stickPickerView.reloadAllComponents()
                }
            },
                      
            onError: { error in
                DispatchQueue.main.async {
                    self.webAppStatusLabel.text = "Stop-NOK"
                    
                    if let error = error {
                        let key = error.userInfo.keys.first!
                        let info = error.userInfo[key] ?? ""
                        self.errorMessageLabel.text = info as? String
                    }
                    
                    OCastLog.error("-> Web app failed to stop")
                }
            }
        )
    }
    
        
// MARK: - Custom Messages

    @IBAction func onCustomStreamSend(_ sender: Any) {
        customAnswerLabel.text = ""
        customStream?.sendCustomMessage (with: 999, onDone: { (result) in
            let key = result.keys.first!
            let val = result[key] as! String
            DispatchQueue.main.async {
                self.customAnswerLabel.text = "\(key): \(val)"
            }
        })
    }
    
    
    @IBAction func onTextFieldSelected(_ sender: UITextField) {
        webAppLabel.text = sender.text
        webAppLabel.placeholder = sender.text
        webAppLabel.textColor = UIColor.lightGray
        
        if sender.text == "" {
            applicationName = "Orange-DefaultReceiver-DEV"
        } else {
            applicationName = sender.text!
        }
        
        webAppLabel.placeholder = applicationName
        webAppLabel.text = applicationName

    }
    
}






