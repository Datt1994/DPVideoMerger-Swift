//
//  DPVideoMerger.swift
//  DPVideoMerger
//
//  Created by datt on 14/02/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit
import AVKit

public final class DPVideoMerger: NSObject {
    //videoQuality : AVAssetExportPresetMediumQuality(default) , AVAssetExportPresetLowQuality , AVAssetExportPresetHighestQuality
    public func mergeVideos(withFileURLs
        videoFileURLs: [URL],
        videoResolution:CGSize = CGSize(width: -1, height: -1),
        videoQuality:String = AVAssetExportPresetMediumQuality,
        completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        
        let composition = AVMutableComposition()
        guard let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            DispatchQueue.main.async { completion(nil, self.videoTarckError()) }
            return
        }
        guard let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            DispatchQueue.main.async { completion(nil, self.audioTarckError()) }
            return
        }
        var instructions = [AVVideoCompositionInstructionProtocol]()
        var isError = false
        var currentTime: CMTime = CMTime.zero
        var videoSize = CGSize.zero
        var highestFrameRate = 0
        if videoResolution == CGSize(width: -1, height: -1) {
        for  videoFileURL in videoFileURLs {
            let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: videoFileURL, options: options)
            guard let videoAsset: AVAssetTrack = asset.tracks(withMediaType: .video).first else {
                return
            }
            if videoSize.equalTo(CGSize.zero) {
                videoSize = (videoAsset.naturalSize)
            }
            var isVideoAssetPortrait_ = false
            let videoTransform: CGAffineTransform = videoAsset.preferredTransform
            
            if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
                isVideoAssetPortrait_ = true
            }
            if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
                isVideoAssetPortrait_ = true
            }
            
            var videoAssetWidth: CGFloat = videoAsset.naturalSize.width
            var videoAssetHeight: CGFloat = videoAsset.naturalSize.height
            if isVideoAssetPortrait_ {
                videoAssetWidth = videoAsset.naturalSize.height
                videoAssetHeight = videoAsset.naturalSize.width
            }
            
            if videoSize.height < (videoAssetHeight) {
                videoSize.height = (videoAssetHeight)
            }
            if videoSize.width < (videoAssetWidth) {
                videoSize.width = (videoAssetWidth)
            }
        }
        } else {
            if (videoResolution.height < 100 || videoResolution.width < 100) {
                DispatchQueue.main.async { completion(nil, self.videoSizeError()) }
                return
            }
            videoSize = videoResolution
        }
        
        for  videoFileURL in videoFileURLs {
            let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: videoFileURL, options: options)
            guard let videoAsset: AVAssetTrack = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async { completion(nil, self.videoTarckError()) }
                return
            }
            guard let audioAsset: AVAssetTrack = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async {completion(nil, self.audioTarckError()) }
                return
            }
            let currentFrameRate = Int(roundf((videoAsset.nominalFrameRate)))
            highestFrameRate = (currentFrameRate > highestFrameRate) ? currentFrameRate : highestFrameRate
            let trimmingTime: CMTime = CMTimeMake(value: Int64(lround(Double((videoAsset.nominalFrameRate) / (videoAsset.nominalFrameRate)))), timescale: Int32((videoAsset.nominalFrameRate)))
            let timeRange: CMTimeRange = CMTimeRangeMake(start: trimmingTime, duration: CMTimeSubtract((videoAsset.timeRange.duration), trimmingTime))
            do {
                try videoTrack.insertTimeRange(timeRange, of: videoAsset, at: currentTime)
                try audioTrack.insertTimeRange(timeRange, of: audioAsset, at: currentTime)
                
                let videoCompositionInstruction = AVMutableVideoCompositionInstruction.init()
                videoCompositionInstruction.timeRange = CMTimeRangeMake(start: currentTime, duration: timeRange.duration)
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                
                var isVideoAssetPortrait_ = false
                let videoTransform: CGAffineTransform = videoAsset.preferredTransform
                var videoAssetOrientation_: UIImage.Orientation = .up
                if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
                    videoAssetOrientation_ = .right
                    isVideoAssetPortrait_ = true
                }
                if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
                    videoAssetOrientation_ = .left
                    isVideoAssetPortrait_ = true
                }
                if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
                    videoAssetOrientation_ = .up
                }
                if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
                    videoAssetOrientation_ = .down
                }
                
                var videoAssetWidth: CGFloat = videoAsset.naturalSize.width
                var videoAssetHeight: CGFloat = videoAsset.naturalSize.height
                if isVideoAssetPortrait_ {
                    videoAssetWidth = videoAsset.naturalSize.height
                    videoAssetHeight = videoAsset.naturalSize.width
                }

                
                
                var tx: Int = 0
                if videoSize.width - videoAssetWidth != 0 {
                    tx = Int((videoSize.width - videoAssetWidth) / 2)
                }
                var ty: Int = 0
                if videoSize.height - videoAssetHeight != 0 {
                    ty = Int((videoSize.height - videoAssetHeight) / 2)
                }
                var Scale = CGAffineTransform(scaleX: 1, y: 1)
                var factor : CGFloat = 1.0
                if tx != 0 && ty != 0 {
                    if tx <= ty {
                        factor = CGFloat(videoSize.width / videoAssetWidth)
                        Scale = CGAffineTransform(scaleX: CGFloat(factor), y: CGFloat(factor))
                        tx = 0
                        ty = Int((videoSize.height - videoAssetHeight * CGFloat(factor)) / 2)
                    }
                    if tx > ty {
                        factor = CGFloat(videoSize.height / videoAssetHeight)
                        Scale = CGAffineTransform(scaleX: CGFloat(factor), y: CGFloat(factor))
                        ty = 0
                        tx = Int((videoSize.width - videoAssetWidth * CGFloat(factor)) / 2)
                    }
                }
               
                
                var Move: CGAffineTransform!
                var transform: CGAffineTransform!
                switch videoAssetOrientation_ {
                case UIImage.Orientation.right:
                    Move = CGAffineTransform(translationX: (videoAssetWidth * factor) + CGFloat(tx)  , y: CGFloat(ty))
                    transform = CGAffineTransform(rotationAngle:degreeToRadian(90))
                layerInstruction.setTransform(transform.concatenating(Scale.concatenating(Move)), at: .zero)
                case UIImage.Orientation.left:
                    Move = CGAffineTransform(translationX: CGFloat(tx), y: videoSize.height - CGFloat(ty))
                    transform = CGAffineTransform(rotationAngle: degreeToRadian(270))
                    layerInstruction.setTransform(transform.concatenating(Scale.concatenating(Move)), at: .zero)
                case UIImage.Orientation.up:
                    Move = CGAffineTransform(translationX: CGFloat(tx), y: CGFloat(ty))
                    layerInstruction.setTransform(Scale.concatenating(Move), at: .zero)
                case UIImage.Orientation.down:
                    Move = CGAffineTransform(translationX: videoSize.width + CGFloat(tx), y: (videoAssetHeight*factor)+CGFloat(ty))
                    transform = CGAffineTransform(rotationAngle: degreeToRadian(180))
                    layerInstruction.setTransform(transform.concatenating(Scale.concatenating(Move)), at: .zero)
                default:
                    break;
                }
//                let Move = CGAffineTransform(translationX: CGFloat(tx), y: CGFloat(ty))
//                layerInstruction.setTransform(Scale.concatenating(Move), at: CMTime.zero)
                videoCompositionInstruction.layerInstructions = [layerInstruction]
                instructions.append(videoCompositionInstruction)
                currentTime = CMTimeAdd(currentTime, timeRange.duration)
            } catch {
                print("Unable to load data: \(error)")
                isError = true
                DispatchQueue.main.async { completion(nil, error) }
            }
        }
        if isError == false {
            let exportSession = AVAssetExportSession(asset: composition, presetName: videoQuality)
            let strFilePath: String = generateMergedVideoFilePath()
            try? FileManager.default.removeItem(atPath: strFilePath)
            exportSession?.outputURL = URL(fileURLWithPath: strFilePath)
            exportSession?.outputFileType = .mp4
            exportSession?.shouldOptimizeForNetworkUse = true
            let mutableVideoComposition = AVMutableVideoComposition.init()
            mutableVideoComposition.instructions = instructions
            mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(highestFrameRate))
            mutableVideoComposition.renderSize = videoSize
            exportSession?.videoComposition = mutableVideoComposition
            print("Composition Duration: %ld s", lround(CMTimeGetSeconds(composition.duration)))
            print("Composition Framerate: %d fps", highestFrameRate)
            let exportCompletion: (() -> Void) = {() -> Void in
                DispatchQueue.main.async(execute: {() -> Void in
                    completion(exportSession?.outputURL, exportSession?.error)
                })
            }
            if let exportSession = exportSession {
                exportSession.exportAsynchronously(completionHandler: {() -> Void in
                    switch exportSession.status {
                    case .completed:
                        print("Successfully merged: %@", strFilePath)
                        exportCompletion()
                    case .failed:
                        print("Failed")
                        exportCompletion()
                    case .cancelled:
                        print("Cancelled")
                        exportCompletion()
                    case .unknown:
                        print("Unknown")
                    case .exporting:
                        print("Exporting")
                    case .waiting:
                        print("Wating")
                    @unknown default:
                        print("default")
                    }
                })
            }
        }
    }
    func videoTarckError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Provide correct video file", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "No video track available", comment: "")]
        return NSError(domain: "DPVideoMerger", code: 404, userInfo: (userInfo as! [String : Any]))
    }
    func audioTarckError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Video file had no Audio track", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "No Audio track available", comment: "")]
        return NSError(domain: "DPVideoMerger", code: 404, userInfo: (userInfo as! [String : Any]))
    }
    func videoSizeError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "videoSize height/width should grater than equal to 100", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "videoSize too small", comment: "")]
        return NSError(domain: "DPVideoMerger", code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    public func gridMergeVideos(withFileURLs
        videoFileURLs: [URL],
        videoResolution: CGSize,
        isRepeatVideo: Bool = false,
        videoDuration: Int = -1,
        videoQuality: String = AVAssetExportPresetMediumQuality,
        completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        if videoFileURLs.count != 4 {
            DispatchQueue.main.async { completion(nil, self.videoCountError()) }
            return
        }
        
        let composition = AVMutableComposition()
        var maxTime = AVURLAsset(url: videoFileURLs[0], options: nil).duration
        for  videoFileURL in videoFileURLs {
            let options = [
                AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true)
            ]
            let asset = AVURLAsset(url: videoFileURL, options: options)
            if CMTimeCompare(maxTime, asset.duration) == -1 {
                maxTime = asset.duration
            }
        }
        if (videoDuration != -1) {
            let videoDurationTime = CMTimeMake(value: Int64(videoDuration), timescale: 1)
            if CMTimeCompare(videoDurationTime, maxTime) == -1 {
                DispatchQueue.main.async { completion(nil, self.videoDurationError()) }
                return
            } else {
                maxTime = CMTimeMake(value: Int64(videoDuration), timescale: 1)
            }
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: maxTime)

        var arrAVMutableVideoCompositionLayerInstruction: [AVMutableVideoCompositionLayerInstruction] = []
        for i in 0 ..< videoFileURLs.count {
            let videoFileURL = videoFileURLs[i]
            let asset = AVURLAsset(url: videoFileURL, options: nil)
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                DispatchQueue.main.async { completion(nil,self.videoTarckError()) }
                return
            }
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: maxTime), of: asset.tracks(withMediaType: .video)[0], at: .zero)
            } catch {
                DispatchQueue.main.async { completion(nil,error) }
                return
            }
            let subInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    
            var Scale = CGAffineTransform(scaleX: 1, y: 1)
            var Move = CGAffineTransform(translationX: 0, y: 0)
            var tx : CGFloat = 0
            if videoResolution.width / 2 - (videoTrack.naturalSize.width) != 0 {
                tx = ((videoResolution.width / 2 - (videoTrack.naturalSize.width)) / 2)
            }
            var ty : CGFloat = 0
            if videoResolution.height / 2 - (videoTrack.naturalSize.height) != 0 {
                ty = ((videoResolution.height / 2 - (videoTrack.naturalSize.height)) / 2)
            }
            if tx != 0 && ty != 0 {
                if tx <= ty {
                    let factor = CGFloat(videoResolution.width / 2 / videoTrack.naturalSize.width)
                    Scale = CGAffineTransform(scaleX: CGFloat(factor), y: CGFloat(factor))
                    tx = 0
                    ty = (videoResolution.height / 2 - videoTrack.naturalSize.height * factor) / 2
                }
                if tx > ty {
                    let factor = CGFloat(videoResolution.height / 2 / videoTrack.naturalSize.height)
                    Scale = CGAffineTransform(scaleX: factor, y: factor)
                    ty = 0
                    tx = (videoResolution.width / 2 - videoTrack.naturalSize.width * factor) / 2
                }
            }
            
            switch i {
                case 0:
                    Move = CGAffineTransform(translationX: CGFloat(0 + tx), y: 0 + ty)
                case 1:
                    Move = CGAffineTransform(translationX: videoResolution.width / 2 + tx, y: 0 + ty)
                case 2:
                    Move = CGAffineTransform(translationX: 0 + tx, y: videoResolution.height / 2 + ty)
                case 3:
                    Move = CGAffineTransform(translationX: videoResolution.width / 2 + tx, y: videoResolution.height / 2 + ty)
                default:
                    break
            }
            
            if (isRepeatVideo) {
                subInstruction.setTransform(Scale.concatenating(Move), at: .zero)
                arrAVMutableVideoCompositionLayerInstruction.append(subInstruction)
                
                var dur = asset.duration
                
                repeat {
                    dur = CMTimeAdd(dur, asset.duration)
                    let atTime = CMTimeSubtract(dur, asset.duration)
                    guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                        DispatchQueue.main.async { completion(nil,self.videoTarckError()) }
                        return
                    }
                    if CMTimeCompare(maxTime, atTime) != 0 {
                        if CMTimeCompare(maxTime, dur) == -1 {
                            let sub = CMTimeSubtract(dur, maxTime)
                            do {
                                try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: CMTimeSubtract(asset.duration, sub)), of: asset.tracks(withMediaType: .video)[0], at: atTime)
                            } catch {
                                DispatchQueue.main.async { completion(nil,error) }
                                return
                            }
                        } else {
                            do {
                                try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: atTime)
                            } catch {
                                DispatchQueue.main.async { completion(nil,error) }
                                return
                            }
                        }
                        let subInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                        subInstruction.setTransform(Scale.concatenating(Move), at: atTime)
                        arrAVMutableVideoCompositionLayerInstruction.append(subInstruction)
                    }
                } while CMTimeCompare(maxTime, dur) != -1
            } else {
                subInstruction.setTransform(Scale.concatenating(Move), at: .zero)
                arrAVMutableVideoCompositionLayerInstruction.append(subInstruction)
            }
            
        }
        
        instruction.layerInstructions = arrAVMutableVideoCompositionLayerInstruction.reversed()

        let MainCompositionInst = AVMutableVideoComposition()
        MainCompositionInst.instructions = [instruction]
        MainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
        MainCompositionInst.renderSize = videoResolution

        let url = URL(fileURLWithPath: generateMergedVideoFilePath())

        let exporter = AVAssetExportSession(asset: composition, presetName: videoQuality)
        exporter?.outputURL = url
        exporter?.videoComposition = MainCompositionInst
        exporter?.outputFileType = .mp4
        
        let exportCompletion: (() -> Void) = {() -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                completion(exporter?.outputURL, exporter?.error)
            })
        }
        if let exportSession = exporter {
            exportSession.exportAsynchronously(completionHandler: {() -> Void in
                switch exportSession.status {
                case .completed:
                    print("Successfully merged: %@", exportSession.outputURL ?? "")
                    exportCompletion()
                case .failed:
                    print("Failed %@",exportSession.error ?? "")
                    exportCompletion()
                case .cancelled:
                    print("Cancelled")
                    exportCompletion()
                case .unknown:
                    print("Unknown")
                case .exporting:
                    print("Exporting")
                case .waiting:
                    print("Wating")
                @unknown default:
                    print("default")
                }
            })
        }
        
    }
    
    func videoCountError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Provide 4 Videos", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "gridMerge required 4 videos to merge", comment: "")]
        return NSError(domain: "DPVideoMerger", code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    func videoDurationError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "videoDuration should grater than equal to logest video duration from all videoes.", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "videoDuration is small to complete videoes", comment: "")]
        return NSError(domain: "DPVideoMerger", code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    func generateMergedVideoFilePath() -> String {
        return URL(fileURLWithPath: ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last)?.path)!).appendingPathComponent("\(UUID().uuidString)-mergedVideo.mp4").path
    }
    func degreeToRadian(_ degree: CGFloat) -> CGFloat {
        return (.pi * degree / 180.0)
    }
}
