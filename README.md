# OCast

[![License](https://img.shields.io/badge/licence-APACHE--2-lightgrey.svg)](https://github.com/Orange-OpenSource/OCast-iOS/blob/master/LICENSE)

[![Pod version](https://badge.fury.io/co/OCast.svg)](https://badge.fury.io/co/OCast)
[![Build Status](https://travis-ci.org/Orange-OpenSource/OCast-iOS.svg?branch=master)](https://travis-ci.org/Orange-OpenSource/OCast-iOS)

The Orange OCast SDK provides all required API methods to implement cast applications to interact with an OCast device.

Both Objective-C and Swift applications may use the Orange OCast SDK to use the APIs defined by the OCast protocol. However Swift is required to use the API to send custom commands.

The sample project aims to demonstrating the basic instruction set of the Orange OCast SDK to help you get started.

## Installation

OCast is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "OCast"
```

You can also retrieve the source code to build the project cloning the repository:

```
git clone https://github.com/Orange-OpenSource/OCast-iOS.git
```

Here's how to import the framework from Swift applications:

```swift
import OCast
```

Here's how to import the framework from Objctive-C applications:

```objc
@import OCast;
```

## Usage

### 1. Register your device(s)

You have to register your device(s) to the `DeviceCenter` for your manufacturer. The manufacturer must be the same as the one in the UPNP device description response.

```swift
let deviceCenter = DeviceCenter()
center.registerDevice(ReferenceDevice.self, forManufacturer: "Manufacturer")
```

### 2. Discovering device(s)

You need to set the `DeviceCenter` delegate and call the `resumeDiscovery` method to start to device discovery.

If devices are found on your network, the `center(_:didAdd:)` method and the `deviceCenterAddDevicesNotification` notification are triggered.

If devices are lost (network problem or turned-off), the `center(_:didRemove:)` method and the `deviceCenterRemoveDevicesNotification` notification are triggered.

```swift
deviceCenter.delegate = self
deviceCenter.reumeDiscovery()

// DeviceCenter delegate methods
func center(_ center: DeviceCenter, didAdd devices: [Device]) {}
func center(_ center: DeviceCenter, didRemove devices: [Device]) {}
func centerDidStop(_ center: DeviceCenter, withError error: Error?) {}
```

You can stop the device discovery calling `stopDiscovery` method. This will trigger the `centerDidStop(_:withError:)` method and the `deviceCenterDiscoveryStoppedNotification` notification. The found devices will be removed, so if you want to keep them you should call `pauseDiscovery` instead. This is useful to manage application background state.

If a network error occurs, the `centerDidStop(_:withError:)` method and the `deviceCenterDiscoveryStoppedNotification` are also called but the error parameter is filled with the issue reason. 

### 3. Use the device

To use OCast media commands on your own application, you must set the device `applicationName`.

```swift
device.applicationName = "MyWebApp"
```

If you want to perform a secure connection, you can set an `SSLConfiguration` object with your custom settings. Then you must call the `connect(_:completion::)` method. The completion block is called without an error if the connection was performed successfully. Then, you can send commands to your device.

```swift
let sslConfiguration = SSLConfiguration()
// Configure your own SSL Configuration
// ...
//
device.connect(sslConfiguration, completion: { error in
    if (error == nil) {
        // Use the commands
    }
})
```

You can disconnect from the device using `disconnect(completion:)`. This is useful to manage application background state for example.

If a network occurs, the `deviceDisconnectedEventNotification` notification is triggered with the issue reason.

### 4. Send an OCast command

You can use the OCast commands provided by the SDK in the `Device` protocol. The command list is described here:  http://ocast.kmt.orange.com/OCast-Protocol.pdf

```swift
device.deviceID(completion: { deviceID, error in
    // ...
})
```

### 5. Receive OCast events

The device can send events defined in the OCast protocol. The following notifications will be triggered depending the event : `playbackStatusEventNotification`, `metadataChangedEventNotification` and `updateStatusEventNotification`.

```swift
// Register to the notification
NotificationCenter.default.addObserver(self, 
                                       selector: #selector(playbackStatusNotification),
                                       name: .playbackStatusEventNotification,
                                       object: device)

// Method triggered for the playback status event
@objc func playbackStatusNotification(_ notification: Notification) {}
```

### 6. Send a custom command

If you need to send a command not defined in the OCast protocol, you can use the `send(_:on:completion)` method.
You must build `OCastMessage` objects for the command and the reply.

```swift
public class CustomCommandCommandParams: OCastMessage {
        
    public let myParameter: String
        
    init (myParameter: String) {
        self.myParameter = myParameter
    }
        
    // ...
}
    
public class CustomCommandReplyParams: OCastMessage {
        
    public let myValue: String
        
    // ...
}

let data = OCastDataLayer(name: "customCommand", params: CustomCommandCommandParams(myParameter: "param"))
let message = OCastApplicationLayer(service: "customService", data: data)
let completionBlock: ResultHandler<CustomCommandReplyParams> = { result, error in
    // result is a CustomCommandReplyParams?
}
device.sender?.send(message, on: .browser, completion: completionBlock)
````

### 7. Receive custom events

If you need to receive an event not defined in the OCast protocol, you can use the `registerEvent(_:completion)` method. The completion block will be called when an event of that name is received.
You must build an `OCastMessage` object for the event.

```swift
public class CustomEvent: OCastMessage {
        
    public let myEventValue: String
        
    // ...
}

device.registerEvent("customEvent", completion: { [weak self] data in
    if let customEvent = try? JSONDecoder().decode(OCastDeviceLayer<CustomEvent>.self, from: data) {
        DispatchQueue.main.async {
            // Update your UI
            self?.myLabel.text = customEvent.message.data.params.myEventValue
        }
    }
})
```

## Sample applications

Both Objective-C and Swift sample applications are available. In order to run these applications properly with your own device, you must set the `OCastDemoManufacturerName` and the `OCastDemoApplicationName` variables.

## Author

Orange

## License

OCast is licensed under the Apache v2 License. See the LICENSE file for more info.
