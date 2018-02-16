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
        var currentTime: CMTime = kCMTimeZero
        var videoSize = CGSize.zero
        var highestFrameRate = 0
        for  videoFileURL in videoFileURLs {
            let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: videoFileURL, options: options)
            let videoAsset: AVAssetTrack? = asset.tracks(withMediaType: .video).first
            if videoSize.equalTo(CGSize.zero) {
                videoSize = (videoAsset?.naturalSize)!
            }
            if videoSize.height < (videoAsset?.naturalSize.height)! {
                videoSize.height = (videoAsset?.naturalSize.height)!
            }
            if videoSize.width < (videoAsset?.naturalSize.width)! {
                videoSize.width = (videoAsset?.naturalSize.width)!
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
            let trimmingTime: CMTime = CMTimeMake(Int64(lround(Double((videoAsset.nominalFrameRate) / (videoAsset.nominalFrameRate)))), Int32((videoAsset.nominalFrameRate)))
            let timeRange: CMTimeRange = CMTimeRangeMake(trimmingTime, CMTimeSubtract((videoAsset.timeRange.duration), trimmingTime))
            do {
                try videoTrack.insertTimeRange(timeRange, of: videoAsset, at: currentTime)
                try audioTrack.insertTimeRange(timeRange, of: audioAsset, at: currentTime)
                
                let videoCompositionInstruction = AVMutableVideoCompositionInstruction.init()
                videoCompositionInstruction.timeRange = CMTimeRangeMake(currentTime, timeRange.duration)
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                
                var tx: Int = 0
                if videoSize.width - videoAsset.naturalSize.width != 0 {
                    tx = Int((videoSize.width - videoAsset.naturalSize.width) / 2)
                }
                var ty: Int = 0
                if videoSize.height - videoAsset.naturalSize.height != 0 {
                    ty = Int((videoSize.height - videoAsset.naturalSize.height) / 2)
                }
                var Scale = CGAffineTransform(scaleX: 1, y: 1)
                if tx != 0 && ty != 0 {
                    if tx <= ty {
                        let factor = Float(videoSize.width / videoAsset.naturalSize.width)
                        Scale = CGAffineTransform(scaleX: CGFloat(factor), y: CGFloat(factor))
                        tx = 0
                        ty = Int((videoSize.height - videoAsset.naturalSize.height * CGFloat(factor)) / 2)
                    }
                    if tx > ty {
                        let factor = Float(videoSize.height / videoAsset.naturalSize.height)
                        Scale = CGAffineTransform(scaleX: CGFloat(factor), y: CGFloat(factor))
                        ty = 0
                        tx = Int((videoSize.width - videoAsset.naturalSize.width * CGFloat(factor)) / 2)
                    }
                }
                let Move = CGAffineTransform(translationX: CGFloat(tx), y: CGFloat(ty))
                layerInstruction.setTransform(Scale.concatenating(Move), at: kCMTimeZero)
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
            mutableVideoComposition.frameDuration = CMTimeMake(1, Int32(highestFrameRate))
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
}
