//
// Notification.swift
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

/// The extension to add OCast notification names.
public extension Notification.Name {
    
    /// The notification sent each time new devices is discovered.
    /// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the new devices.
    static let deviceCenterAddDevicesNotification = Notification.Name("OCastDeviceCenterAddDevices")
    
    /// The notification sent each time devices has been removed.
    /// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the devices removed.
    static let deviceCenterRemoveDevicesNotification = Notification.Name("OCastDeviceCenterRemoveDevices")
    
    /// Notification sent each time an error has occured during discovery.
    /// The userinfo `DeviceCenterErrorUserInfoKey` key contains an error if it occurs.
    static let deviceCenterDiscoveryErrorNotification = Notification.Name("OCastDeviceCenterDiscoveryError")
    
    /// The notification sent when the device is disconnected
    /// The userinfo `ErrorUserInfoKey` key contains error information.
    static let deviceDisconnectedEventNotification = Notification.Name("OCastDeviceDisconnectedEvent")

    /// The notification sent when a playback status event is received.
    /// The userinfo `PlaybackStatusUserInfoKey` key contains playback status information.
    static let playbackStatusEventNotification = Notification.Name("OCastPlaybackStatusEvent")
    
    /// The notification sent when a metadata event is received.
    /// The userinfo `MetadataUserInfoKey` key contains metadata information.
    static let metadataChangedEventNotification = Notification.Name("OCastMetadataChangedEvent")
    
    /// The notification sent when an update status event is received.
    /// The userinfo `UpdateStatusUserInfoKey` key contains update status information.
    static let updateStatusEventNotification = Notification.Name("OCastUpdateStatusEvent")
}

/// The extension to export the OCast notification name to Objective-C.
@objc
public extension NSNotification {
    
    /// The notification sent each time new devices is discovered.
    /// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the new devices.
    static let deviceCenterAddDevicesNotification = Notification.Name.deviceCenterAddDevicesNotification
    
    /// The notification sent each time devices has been removed.
    /// The userinfo `DeviceCenterDevicesUserInfoKey` key contains an array with the devices removed.
    static let deviceCenterRemoveDevicesNotification = Notification.Name.deviceCenterRemoveDevicesNotification
    
    /// Notification sent each time an error has occured during discovery.
    /// The userinfo `DeviceCenterErrorUserInfoKey` key contains an error if it occurs.
    static let deviceCenterDiscoveryErrorNotification = Notification.Name.deviceCenterDiscoveryErrorNotification
    
    /// The notification sent when the device is disconnected
    /// The userinfo `ErrorUserInfoKey` key contains error information.
    static let deviceDisconnectedEventNotification = Notification.Name.deviceDisconnectedEventNotification
    
    /// The notification sent when a playback status event is received.
    /// The userinfo `PlaybackStatusUserInfoKey` key contains playback status information.
    static let playbackStatusEventNotification = Notification.Name.playbackStatusEventNotification
    
    /// The notification sent when a metadata event is received.
    /// The userinfo `MetadataUserInfoKey` key contains metadata information.
    static let metadataChangedEventNotification = Notification.Name.metadataChangedEventNotification
    
    /// The notification sent when an update status event is received.
    /// The userinfo `UpdateStatusUserInfoKey` key contains update status information.
    static let updateStatusEventNotification = Notification.Name.updateStatusEventNotification
}

/// The class to describe the device center notification user info key constants to use it in Swift and Objective-C.
@objc
@objcMembers
public class DeviceCenterUserInfoKey: NSObject {
    
    /// The notification user info key representing the devices.
    public static let deviceCenterDevicesUserInfoKey = "OCastDeviceCenterDevicesUserInfoKey"
    
    /// The notification user info key representing the error when the discovery is stopped.
    public static let deviceCenterErrorUserInfoKey = "OCastDeviceCenterErrorUserInfoKey"
}

/// The class to describe the device notification user info key constants to use it in Swift and Objective-C.
@objc
@objcMembers
public class DeviceUserInfoKey: NSObject {
    
    /// The notification user info key representing the error.
    public static let errorUserInfoKey = "OCastErrorKey"
    
    /// The notification user info key representing the playback status.
    public static let playbackStatusUserInfoKey = "OCastPlaybackStatusKey"
    
    /// The notification user info key representing the metadata.
    public static let metadataUserInfoKey = "OCastMetadataKey"
    
    /// The notification user info key representing the update status.
    public static let updateStatusUserInfoKey = "OCastUpdateStatusKey"
}
