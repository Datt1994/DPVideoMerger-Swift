//
//  DPVideoMerger.swift
//  DPVideoMerger
//
//  Created by datt on 14/02/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit
import AVKit

class DPVideoMerger: NSObject {
    func mergeVideos(withFileURLs videoFileURLs: [URL], completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        
        let composition = AVMutableComposition()
        guard let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil, videoTarckError())
            return
        }
        guard let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil, audioTarckError())
            return
        }
        var instructions = [AVVideoCompositionInstructionProtocol]()
        var isError = false
        var currentTime: CMTime = CMTime.zero
        var videoSize = CGSize.zero
        var highestFrameRate = 0
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
        
        for  videoFileURL in videoFileURLs {
            let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: videoFileURL, options: options)
            guard let videoAsset: AVAssetTrack = asset.tracks(withMediaType: .video).first else {
                completion(nil, videoTarckError())
                return
            }
            guard let audioAsset: AVAssetTrack = asset.tracks(withMediaType: .audio).first else {
                completion(nil, audioTarckError())
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
                completion(nil, error)
            }
        }
        if isError == false {
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
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
                        fatalError()
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
    func generateMergedVideoFilePath() -> String {
        return URL(fileURLWithPath: ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last)?.path)!).appendingPathComponent("\(UUID().uuidString)-mergedVideo.mp4").path
    }
    func degreeToRadian(_ degree: CGFloat) -> CGFloat {
        return (.pi * degree / 180.0)
    }
}
