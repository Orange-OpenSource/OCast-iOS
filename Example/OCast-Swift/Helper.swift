//
// Helper.swift
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


import Foundation
import OCast

extension Double {
    
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension MainVC {
    

    // MARK: - UI
    
    func setupUI () {
        
        DispatchQueue.main.async {
            self.navigationController?.isToolbarHidden = false
            
            self.stickStatusLabel.text = ""
            self.stickNameLabel.text = "No stick selected yet"
            
            self.webAppLabel.text = self.applicationName
            self.webAppLabel.textColor = UIColor.lightGray
            self.webAppLabel.delegate = self
            self.webAppLabel.returnKeyType = .done
            self.webAppStatusLabel.text = "--"
            
            self.errorMessageLabel.text = ""
            self.errorSettingLabel.text = ""
            
            self.connectedButton.image = nil
            
            self.audioTrackButton.isHidden = true
            self.videoTrackButton.isHidden = true
            self.textTrackButton.isHidden = true
            
            self.stickPickerView.delegate = self
            self.stickPickerView.dataSource = self
            
            self.connectedButton.isEnabled = false
        }
    }
    
    func setUIStickSelected () {
        DispatchQueue.main.async {
            self.connectedButton.isEnabled = true
            self.connectedButton.image = #imageLiteral(resourceName: "playto_noconnected")
            self.connectedButton.tintColor =  UIColor.black
            self.stickStatusLabel.text = "Selected"
        }
    }
    
    func setUIStickDisconnected () {
        DispatchQueue.main.async {
            if self.devices.count == 0 {
                self.setupUI()
            } else {
                
                self.connectedButton.image = #imageLiteral(resourceName: "playto_noconnected")
                self.connectedButton.tintColor = UIColor.black
                self.stickStatusLabel.text = "Disconnected"
            }
        }
    }
    
    func setUIWebAppConnected () {
        DispatchQueue.main.async {
            self.connectedButton.image = #imageLiteral(resourceName: "playto_connected")
            self.connectedButton.tintColor = UIColor.orange
            self.stickStatusLabel.text = "Connected"
        }
    }
    
    func setUIWebAppDisconnected () {
        DispatchQueue.main.async {
            self.connectedButton.image = #imageLiteral(resourceName: "playto_noconnected")
            self.connectedButton.tintColor = UIColor.black
            self.stickStatusLabel.text = "Disconnected"
        }
    }
    
    
    // MARK: - Reset actions
    
    func resetContext () {
        customStream = nil
        mediaController = nil
        appliMgr = nil
        connectedButton.isEnabled = false
        
        setUIStickDisconnected ()
    }
    
    // MARK: - Device Manager
    
    func createDeviceManager(with device:Device) {
        deviceMgr = DeviceManager(with: device, withCertificateInfo: nil)
        deviceMgr?.delegate = self
    }

    // MARK: - Context settings
    
    func setupWebAppCtx(onSuccess:@escaping () -> (), onError:@escaping (_ error: NSError?) -> ()) {
        
        if appliMgr == nil {
            deviceMgr?.getApplicationController(for: applicationName,
                                                onSuccess: {response in
                                                    self.appliMgr = response
                                                    
                                                    if self.customStream == nil {
                                                        self.customStream = CustomStream()
                                                        self.appliMgr?.manageStream(for: self.customStream!)
                                                    }
                                                    
                                                    if self.mediaController == nil {
                                                        self.mediaController = self.appliMgr?.getMediaController(for: self)
                                                    }
                                                    
                                                    onSuccess()
                                                    self.setUIWebAppConnected ()
                                                },
                                                
                                                onError: {error in
                                                    
                                                    DispatchQueue.main.async {
                                                        OCastLog.debug ("-> ERROR for Application Manager = \(String(describing: error))")
                                                        if let error = error {
                                                            let key = error.userInfo.keys.first!
                                                            let info = error.userInfo[key] ?? ""
                                                            self.errorSettingLabel.text = info as? String
                                                        }
                                                    }
            })
            
        } else {
            onSuccess()
        }
    }
    
    // MARK: - TextField delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        webAppLabel.text = ""
        return true
    }
    
    // MARK: - PickerView delegates
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return devices.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if row < devices.count {
            return devices[row].friendlyName
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row < devices.count {
            stickStatusLabel.text = "CléTV : \(devices[row].friendlyName)"
            onDeviceSelected(device: devices[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.textAlignment = .center
            pickerLabel?.font = UIFont(name: "Helvetica", size: 14.0)
        }
        
        if row < devices.count {
            pickerLabel?.text = devices[row].friendlyName
            pickerLabel?.textColor = UIColor.black
        } else {
            pickerLabel?.text = ""
        }
        
        return pickerLabel!
    }
}

