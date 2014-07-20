# ASMScaleKit

[![CI Status](http://img.shields.io/travis/Andrew Molloy/ASMScaleKit.svg?style=flat)](https://travis-ci.org/Andrew Molloy/ASMScaleKit)
[![Version](https://img.shields.io/cocoapods/v/ASMScaleKit.svg?style=flat)](http://cocoadocs.org/docsets/ASMScaleKit)
[![License](https://img.shields.io/cocoapods/l/ASMScaleKit.svg?style=flat)](http://cocoadocs.org/docsets/ASMScaleKit)
[![Platform](https://img.shields.io/cocoapods/p/ASMScaleKit.svg?style=flat)](http://cocoadocs.org/docsets/ASMScaleKit)

ASMScaleKit is an Objective-C wrapper for the Withings Smart Scale API, with the goal of being able to add other support for other smart scale vendors in the future.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first. You will need to register with Withings at http://oauth.withings.com/api. To use the Example app, create a plist file called Examples/ASMScaleKit/WithingsKeys.plist. It should have two entries, "key" and "secret", each containing the consumer key and secret assigned by Withings respectively.

## Requirements

iOS 7.0+. OS X support is forthcoming.

You must be register an application with Withings to use this library.

## Installation

ASMScaleKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "ASMScaleKit"

## Author

Andy Molloy, amolloy@gmail.com

## License

ASMScaleKit is available under the MIT license. See the LICENSE file for more info.

