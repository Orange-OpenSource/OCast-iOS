# OCast

[![License](https://img.shields.io/badge/licence-APACHE--2-lightgrey.svg)](https://github.com/Orange-OpenSource/OCast-iOS/blob/master/LICENSE)

[![Pod version](https://badge.fury.io/co/OCast.svg)](https://badge.fury.io/co/OCast)
[![Build Status](https://travis-ci.org/Orange-OpenSource/OCast-iOS.svg?branch=master)](https://travis-ci.org/Orange-OpenSource/OCast-iOS)

The Orange OCast SDK provides all required API methods to implement cast applications to interact with an OCast device.

Both Objective-C and Swift applications may use the Orange OCast SDK.

The Example project aims at demonstrating the basic instruction set of the Orange OCast SDK to help you get started.

## Installation

OCast is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OCast"
```

You can also retrieve the source code to build the project cloning the repository with the recursive option to pull submodules:

```
git clone --recursive https://github.com/Orange-OpenSource/OCast-iOS.git
```

Here's how to import the framework from Objctive-C applications

```
@import OCast;
```

Here's how to import the framework from Swift applications

```
import OCast
```

## Usage

### 1. Create your device(s)

You can use the ReferenceDevice by adding it two mandatory information (manufacturer name and the search target 

```
public class CustomDevice: Device, DeviceProtocol {
    public static var manufacturer: String = "manufacturer"
    public  static  var searchTarget: String = "urn:cast-ocast-org:service:cast:1"
}
```
Or
```
extension Device: DeviceProtocol {
    public static var manufacturer: String = "manufacturer"
    public  static  var searchTarget: String = "urn:cast-ocast-org:service:cast:1"
}
```

You can also develop your own Device by implementing the DeviceProtocol protocol

```
public class CustomDevice: DeviceProtocol {
// Implements DeviceProtocol
}
```

### 2. Register your device(s)

You have to register your device(s) to a Center

```
let center = DeviceCenter()
center.registerDevice(CustomDevice.self)
```

### 3. Discovering device(s)

Add a delegate to the center and start to discover device(s)

```
center.delegate = self
center.startDiscovery()

// DeviceCenter delegate methods
func discovery(_ center: OCastCenter, didAddDevice device: DeviceProtocol) {
    self.device = device
}
```

### 4. Use the device

```
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

### 5. Send command

You can send directly  settings command :
```
device.deviceID({ (deviceID, error) in
    // ...
})
```

You need to set an application's name before sending media commands :
```
device.applicationName = "You application name"
device.prepare(command, withOptions: nil, completion: { error in

})
```

## Author

Orange

## License

OCast is licensed under the Apache v2 License. See the LICENSE file for more info.
