# OCast

[![License](https://img.shields.io/badge/licence-APACHE--2-lightgrey.svg)](https://github.com/Orange-OpenSource/OCast-iOS/blob/travisBranch/LICENSE)

[![Pod version](https://badge.fury.io/co/OCast.svg)](https://badge.fury.io/co/OCast)
[![Build Status](https://travis-ci.org/Orange-OpenSource/OCast-iOS.png)](https://travis-ci.org/Orange-OpenSource/OCast-iOS)

The Orange OCast SDK provides all required API methods to implement cast applications for the Orange stick.

Both Objective C and Swift applications may use the Orange OCast SDK.

The Example project aims at demonstrating the basic instruction set of the Orange OCast SDK to help you get started.

Here are the main functionalities of the Example project:


```
• Wifi connection to the receiver

• Application stop and restart

• Audio cast Play/Pause/Stop

• Video cast Play/Pause/Stop

• Image cast

• Volume control

• Time seek management

• Media tracks management

• Custom messages handling

```

You don't need to have a stick to run the Exmaple project or to start developping your own application. You can use our simulator to get started (see [OCast-DongleTV-JS](https://github.com/Orange-OpenSource/OCast-DongleTV-JS) for more details).

Quick steps to get the simulator up and running:

```
$git clone https://github.com/Orange-OpenSource/OCast-DongleTV-JS.git

$cd OCast-DongleTV-JS

$npm install

$npm start
```
## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

One scheme per language is available (OCastExample-ObjC and OcastExample-Swift).

## Installation

OCast is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OCast"
```

Here's how to import the framework from Objctive-C applications

```
@import OCast;
```

Here's how to import the framework from Swift applications

```
import OCast
```




## Author

Orange

## License

OCast is licensed under the Apache v2 License. See the LICENSE file for more info.
