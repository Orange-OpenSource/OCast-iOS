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

import OCast
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var castButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pauseResumeButton: UIButton!
    @IBOutlet weak var progressionSlider: UISlider!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var metadataButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    /// The devivce.
    var device: Device!
    
    /// The current playback status.
    private var currentPlaybackStatus: MediaPlaybackStatus? {
        didSet {
            updateUI()
        }
    }
    
    /// The time formatter.
    private let timeFormatter = DateComponentsFormatter()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        timeFormatter.zeroFormattingBehavior = .pad
    }
    
    deinit {
        device.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = device.friendlyName
        device.applicationName = OCastDemoApplicationName
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackStatusNotification),
                                               name: .playbackStatusEventNotification,
                                               object: device)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updatePlaybackStatus()
    }
    
    // MARK: - Private methods
    
    private func connect(completion: @escaping (Bool) -> Void) {
        let sslConfiguration = SSLConfiguration()
        sslConfiguration.disablesSSLCertificateValidation = true
        device.connect(sslConfiguration) { [weak self] error in
            if let error = error {
                self?.show(error, beforeControllerDismissed: true)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func show(_ error: Error, beforeControllerDismissed: Bool = false) {
        let alertController = UIAlertController(title: "OCastDemo", message: error.localizedDescription, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            if beforeControllerDismissed {
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func ensureConnected(completion: @escaping (Bool) -> Void) {
        if device.state != .connected {
            connect(completion: completion)
        } else {
            completion(true)
        }
    }
    
    private func updatePlaybackStatus() {
        ensureConnected { [weak self] connected in
            if connected {
                self?.device.playbackStatus(completion: { playbackStatus, error in
                    if let error = error {
                        self?.show(error)
                    } else {
                        self?.currentPlaybackStatus = playbackStatus
                    }
                })
            }
        }
    }
    
    private func updateUI() {
        guard let currentPlaybackStatus = currentPlaybackStatus else { return }
        
        switch currentPlaybackStatus.state {
        case .idle, .unknown:
            castButton.isEnabled = true
            stopButton.isEnabled = false
            pauseResumeButton.isEnabled = false
            progressionSlider.isEnabled = false
            progressionSlider.setValue(0.0, animated: true)
            startLabel.text = "-"
            endLabel.text = "-"
            volumeSlider.isEnabled = false
            volumeSlider.setValue(0.0, animated: true)
            metadataButton.isEnabled = false
            titleLabel.text = "-"
            subtitleLabel.text = "-"
        case .buffering, .playing, .paused:
            castButton.isEnabled = false
            stopButton.isEnabled = true
            pauseResumeButton.isEnabled = true
            pauseResumeButton.setTitle(currentPlaybackStatus.state == .paused ? "Resume" : "Pause", for: .normal)
            progressionSlider.isEnabled = true
            progressionSlider.setValue(Float(currentPlaybackStatus.position / currentPlaybackStatus.duration), animated: true)
            startLabel.text = timeFormatter.string(from: currentPlaybackStatus.position) ?? "-"
            endLabel.text = timeFormatter.string(from: currentPlaybackStatus.duration) ?? "-"
            volumeSlider.isEnabled = true
            volumeSlider.setValue(currentPlaybackStatus.volume, animated: true)
            metadataButton.isEnabled = true
        }
    }
    
    // MARK: - UI events methods
    
    @IBAction func castButtonClicked(_ sender: Any) {
        let mediaPrepareCommand = MediaPrepareCommand(url: OCastDemoMovieURLString,
                                                      frequency: 1,
                                                      title: "Movie Sample",
                                                      subtitle: "OCast",
                                                      logo: "",
                                                      mediaType: .video,
                                                      transferMode: .buffered,
                                                      autoPlay: true)
        ensureConnected { [weak self] connected in
            if connected {
                self?.device.prepare(mediaPrepareCommand, completion: { error in
                    if let error = error {
                        self?.show(error)
                    }
                })
            }
        }
    }
    
    @IBAction func stopButtonClicked(_ sender: Any) {
        ensureConnected { [weak self] connected in
            if connected {
                self?.device.stop(completion: { error in
                    if let error = error {
                        self?.show(error)
                    }
                })
            }
        }
    }
    
    @IBAction func pauseResumeButtonClicked(_ sender: Any) {
        ensureConnected { [weak self] connected in
            if connected {
                if self?.currentPlaybackStatus?.state == .paused {
                    self?.device.resume(completion: { error in
                        if let error = error {
                            self?.show(error)
                        }
                    })
                } else {
                    self?.device.pause(completion: { error in
                        if let error = error {
                            self?.show(error)
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func progressionSliderChanged(_ sender: Any) {
        guard let currentPlaybackStatus = currentPlaybackStatus else { return }
        
        ensureConnected { [weak self] connected in
            guard let `self` = self else { return }
            if connected {
                let position = Double(self.progressionSlider.value) * currentPlaybackStatus.duration
                self.device.seek(to: position, completion: { error in
                    if let error = error {
                        self.show(error)
                    }
                })
            }
        }
    }
    @IBAction func volumeSliderChanged(_ sender: Any) {
        ensureConnected { [weak self] connected in
            guard let `self` = self else { return }
            if connected {
                self.device.setVolume(self.volumeSlider.value, completion: { error in
                    if let error = error {
                        self.show(error)
                    }
                })
            }
        }
    }
    
    @IBAction func metadataButtonClicked(_ sender: Any) {
        ensureConnected { [weak self] connected in
            if connected {
                self?.device.metadata(completion: { metadata, error in
                    if let error = error {
                        self?.show(error)
                    } else if let metadata = metadata {
                        self?.titleLabel.text = "Titre: \(metadata.title)"
                        self?.subtitleLabel.text = "Sous-titre: \(metadata.subtitle)"
                    }
                })
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc func playbackStatusNotification(_ notification: Notification) {
        currentPlaybackStatus = notification.userInfo?[DeviceUserInfoKey.playbackStatusUserInfoKey] as? MediaPlaybackStatus
    }
    
    @objc func applicationDidEnterBackground() {
        device.disconnect()
    }
    
    @objc func applicationWillEnterForeground() {
        updatePlaybackStatus()
    }
}
