//
//  RootViewController.swift
//  OCastDemoSwift
//
//  Created by François Suc on 24/06/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import OCast
import Reachability
import UIKit

class RootViewController: UITableViewController, DeviceCenterDelegate {
    
    /// The device center.
    let deviceCenter = DeviceCenter()
    
    /// The devices found on the local network.
    var devices = [Device]()
    
    /// The object to monitor the network.
    let reachability = Reachability()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        deviceCenter.delegate = self
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
        
        // Register a device and start to search the sticks on the local network.
        deviceCenter.registerDevice(ReferenceDevice.self, forManufacturer: OCastDemoManufacturerName)
        deviceCenter.resumeDiscovery()
        
        reachability?.whenReachable = { [weak self] reachability in
            if reachability.connection == .wifi {
                self?.deviceCenter.resumeDiscovery()
            } else {
                self?.deviceCenter.stopDiscovery()
            }
        }
        reachability?.whenUnreachable = { [weak self] _ in
            self?.deviceCenter.stopDiscovery()
        }
        
        do {
            try reachability?.startNotifier()
        } catch {}
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stickCellIdentifier", for: indexPath)
        
        cell.textLabel?.text = devices[indexPath.row].friendlyName
        
        return cell
    }
    
    // MARK: - DeviceCenter methods
    
    func center(_ center: DeviceCenter, didAdd devices: [Device]) {
        self.devices.append(contentsOf: devices)
        tableView.reloadData()
    }
    
    func center(_ center: DeviceCenter, didRemove devices: [Device]) {
        devices.forEach { device in
            if let index = self.devices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
                self.devices.remove(at: index)
            }
        }
        tableView.reloadData()
    }
    
    func centerDidStop(_ center: DeviceCenter, withError error: Error?) {
        navigationController?.popToRootViewController(animated: false)
        if let error = error {
            let alertController = UIAlertController(title: "OCastDemo",
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let deviceCell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: deviceCell),
            let detailViewController = segue.destination as? DetailViewController {
            
            detailViewController.device = devices[indexPath.row]
        }
    }
    
    // MARK: - Notifications
    
    @objc func applicationDidEnterBackground() {
        deviceCenter.pauseDiscovery()
    }
    
    @objc func applicationWillEnterForeground() {
        deviceCenter.resumeDiscovery()
    }
}
