# DPVideoMerger-Swift

[![Platform](https://img.shields.io/cocoapods/p/DPVideoMerger-Swift.svg?style=flat)](http://cocoapods.org/pods/DPVideoMerger-Swift)
[![Language: Swift 5](https://img.shields.io/badge/language-swift5-f48041.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/cocoapods/l/DPVideoMerger-Swift.svg?style=flat)](https://github.com/Datt1994/DPVideoMerger-Swift/blob/master/LICENSE)
[![Version](https://img.shields.io/cocoapods/v/DPVideoMerger-Swift.svg?style=flat)](http://cocoapods.org/pods/DPVideoMerger-Swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

**For Objective C** :- [DPVideoMerger](https://github.com/Datt1994/DPVideoMerger)

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C. You can install it with the following command:

```bash
$ gem install cocoapods
```
#### Podfile

To integrate DPVideoMerger into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
use_frameworks!
pod 'DPVideoMerger-Swift'
end
```

Then, run the following command:

```bash
$ pod install
```

## Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate `DPVideoMerger-Swift` into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Datt1994/DPVideoMerger-Swift"
```

Run `carthage` to build the framework and drag the framework (`DPVideoMerger_Swift.framework`) into your Xcode project.


## Add Manually 
  
  Download Project and copy-paste `DPVideoMerger.swift` file into your project 

## Usage 

```swift
import AVKit

let fileURL = Bundle.main.url(forResource: "1", withExtension: "mp4")
let fileURL1 = Bundle.main.url(forResource: "2", withExtension: "mp4")
let fileURL2 = Bundle.main.url(forResource: "3", withExtension: "MOV")
let fileURL3 = Bundle.main.url(forResource: "4", withExtension: "mp4")
let fileURLs = [fileURL, fileURL1, fileURL2, fileURL3]

DPVideoMerger().mergeVideos(withFileURLs: fileURLs as! [URL], completion: {(_ mergedVideoFile: URL?, _ error: Error?) -> Void in
    if error != nil {
        let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (a) in
        }))
        self.present(alert, animated: true) {() -> Void in }
        return
    }
    let objAVPlayerVC = AVPlayerViewController()
    objAVPlayerVC.player = AVPlayer(url: mergedVideoFile!)
    self.present(objAVPlayerVC, animated: true, completion: {() -> Void in
        objAVPlayerVC.player?.play()
    }) 
})

DPVideoMerger().gridMergeVideos(withFileURLs: fileURLs, videoResolution: CGSize(width: 1000, height: 1000), completion: {(_ mergedVideoFile: URL?, _ error: Error?) -> Void in
    if error != nil {
        let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (a) in
        }))
        self.present(alert, animated: true) {() -> Void in }
        return
    }
    let objAVPlayerVC = AVPlayerViewController()
    objAVPlayerVC.player = AVPlayer(url: mergedVideoFile!)
    self.present(objAVPlayerVC, animated: true, completion: {() -> Void in
        objAVPlayerVC.player?.play()
    })
})
```
