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


## Installation with Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

To add the library as package dependency to your Xcode project, select File > Swift Packages > Add Package Dependency and enter its repository URL `https://github.com/Datt1994/DPVideoMerger-Swift.git`


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


/// Multiple videos merge in one video with manage scale & aspect ratio
/// - Parameters:
///   - videoFileURLs: Video file path URLs, Array of videos that going to merge
///   - videoResolution: Output video resolution, (defult:  CGSize(width: -1, height: -1), find max width and height from provided videos)
///   - videoQuality: AVAssetExportPresetMediumQuality(default) , AVAssetExportPresetLowQuality , AVAssetExportPresetHighestQuality
///   - completion: Completion give  2 optional  values, 1)mergedVideoURL: URL path of successfully merged video   2)error: Gives Error object if some error occur in videos merging process
///   - mergedVideoURL: URL path of successfully merged video
///   - error: Gives Error object if some error occur in videos merging process
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


/// Merge  videos to grid matrix layout
/// - Parameters:
///   - videoFileURLs: Video file path URLs, Array of videos that going to grid merge
///   - matrix: Video matrix position (eg 3x3, 4x2, 1x3, ...) (default:- 2x2)
///   - audioFileURL: Optional audio file for Merged Video
///   - videoResolution: Output video resolution
///   - isRepeatVideo: Repeat Video on grid if one or more video have shorter duartion time then output video duration
///   - isRepeatAudio: Repeat Audio if Merged video have longer duartion time then provided Audio duration
///   - isAudio: Allow Audio for grid video (default :- true)
///   - videoDuration: Output video duration (defult:  -1, find max duration from provided  videos)
///   - videoQuality: AVAssetExportPresetMediumQuality(default) , AVAssetExportPresetLowQuality , AVAssetExportPresetHighestQuality
///   - completion: completion give  2 optional  values, 1)mergedVideoURL: URL path of successfully grid merged video  2)error: gives Error object if some error occur in videos merging process
///   - mergedVideoURL: URL path of successfully grid merged video
///   - error: gives Error object if some error occur in videos merging process
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
