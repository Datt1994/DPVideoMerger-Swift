//
//  DPVideoMerger.swift
//  DPVideoMerger
//
//  Created by datt on 14/02/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit
import AVKit



@objc protocol VideoMerger {
    func mergeVideos(withFileURLs videoFileURLs: [URL], videoResolution:CGSize, videoQuality:String, completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void)
    func gridMergeVideos(withFileURLs videoFileURLs: [URL], matrix: DPVideoMatrix, audioFileURL: URL?, videoResolution: CGSize, isRepeatVideo: Bool, isRepeatAudio: Bool, isAudio: Bool,videoDuration: Int, videoQuality: String, completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void)
    func parallelMergeVideos(withFileURLs videoFileURLs: [URL], audioFileURL: URL?, videoResolution: CGSize, isRepeatVideo: Bool, isRepeatAudio: Bool, videoDuration: Int, videoQuality: String, alignment: ParallelMergeAlignment, completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void)
}

@objc public enum ParallelMergeAlignment : Int {
    case vertical
    case horizontal
}

@objc open class DPVideoMatrix: NSObject {
    @objc fileprivate var rows: UInt
    @objc fileprivate var columns: UInt
    
    public init(rows: UInt, columns: UInt) {
        self.rows = rows
        self.columns = columns
    }
    
    @objc public func initWith(rows: UInt, columns: UInt) {
        self.rows = rows
        self.columns = columns
    }
}

@objc open class DPVideoMerger : NSObject {
}
// MARK:-  Public Functions
extension DPVideoMerger : VideoMerger {
    /// Multiple videos merge in one video with manage scale & aspect ratio
    /// - Parameters:
    ///   - videoFileURLs: Video file path URLs, Array of videos that going to merge
    ///   - videoResolution: Output video resolution, (defult:  CGSize(width: -1, height: -1), find max width and height from provided videos)
    ///   - videoQuality: AVAssetExportPresetMediumQuality(default) , AVAssetExportPresetLowQuality , AVAssetExportPresetHighestQuality
    ///   - completion: Completion give  2 optional  values, 1)mergedVideoURL: URL path of successfully merged video   2)error: Gives Error object if some error occur in videos merging process
    ///   - mergedVideoURL: URL path of successfully merged video
    ///   - error: Gives Error object if some error occur in videos merging process
    open func mergeVideos(withFileURLs
        videoFileURLs: [URL],
        videoResolution:CGSize = CGSize(width: -1, height: -1),
        videoQuality:String = AVAssetExportPresetMediumQuality,
        completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        if videoFileURLs.count <= 1 {
            DispatchQueue.main.async { completion(nil, self.videoMoreThenOneError()) }
            return
        }
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
                let videoAssetOrientation_ = videoAssetOrientation(videoAsset)
                if videoAssetOrientation_ == .right || videoAssetOrientation_ == .left { isVideoAssetPortrait_ = true }
                
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
                    transform = CGAffineTransform(rotationAngle: degreeToRadian(90))
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
                debugPrint("Unable to load data: \(error)")
                isError = true
                DispatchQueue.main.async { completion(nil, error) }
            }
        }
        if isError == false {
            exportMergedVideo(instructions, highestFrameRate, videoSize, composition, videoQuality, completion)
        }
    }
    
    /// Merge videos to grid matrix layout
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
    open func gridMergeVideos(withFileURLs
        videoFileURLs: [URL],
        matrix: DPVideoMatrix = DPVideoMatrix(rows: 2, columns: 2),
        audioFileURL: URL? = nil,
        videoResolution: CGSize,
        isRepeatVideo: Bool = false,
        isRepeatAudio: Bool = false,
        isAudio: Bool = true,
        videoDuration: Int = -1,
        videoQuality: String = AVAssetExportPresetMediumQuality,
        completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        if videoFileURLs.count <= 1 {
            DispatchQueue.main.async { completion(nil, self.videoMoreThenOneError()) }
            return
        }
        let rows: CGFloat = CGFloat(matrix.rows)
        let columns: CGFloat = CGFloat(matrix.columns)
        if rows == 0 || columns == 0 {
            DispatchQueue.main.async { completion(nil, self.gridMatrixError()) }
            return
        }
        var videoFileURLs = videoFileURLs
        if videoFileURLs.count > Int(rows * columns) {
            videoFileURLs = videoFileURLs.dropLast(videoFileURLs.count - Int(rows * columns))
        }
        if (videoResolution.height < 100 || videoResolution.width < 100) {
            DispatchQueue.main.async { completion(nil, self.videoSizeError()) }
            return
        }
        
        let composition = AVMutableComposition()
        var maxTime = maxTimeFromVideos(videoFileURLs)
        var highestFrameRate = 0
        
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
            guard let videoAsset = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async { completion(nil,self.videoTarckError()) }
                return
            }
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: maxTime), of: videoAsset, at: .zero)
            } catch {
                DispatchQueue.main.async { completion(nil,error) }
                return
            }
            let currentFrameRate = Int(roundf((videoTrack.nominalFrameRate)))
            highestFrameRate = (currentFrameRate > highestFrameRate) ? currentFrameRate : highestFrameRate
            
            var isVideoAssetPortrait_ = false
            let videoAssetOrientation_ = videoAssetOrientation(videoAsset)
            if videoAssetOrientation_ == .right || videoAssetOrientation_ == .left { isVideoAssetPortrait_ = true }
            
            var videoAssetWidth: CGFloat = videoAsset.naturalSize.width
            var videoAssetHeight: CGFloat = videoAsset.naturalSize.height
            if isVideoAssetPortrait_ {
                videoAssetWidth = videoAsset.naturalSize.height
                videoAssetHeight = videoAsset.naturalSize.width
            }
            
            
            let subInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    
            var Scale = CGAffineTransform(scaleX: 1, y: 1)
            var Move = CGAffineTransform(translationX: 0, y: 0)
            var factor:CGFloat = 1.0
            var tx : CGFloat = 0
            if videoResolution.width / columns - (videoAssetWidth) != 0 {
                tx = ((videoResolution.width / columns - videoAssetWidth) / 2)
            }
            var ty : CGFloat = 0
            if videoResolution.height / rows - (videoAssetHeight) != 0 {
                ty = ((videoResolution.height / rows - videoAssetHeight) / 2)
            }
            if tx != 0 && ty != 0 {
                let factorWidth = CGFloat(videoResolution.width / columns / videoAssetWidth)
                let factorHeight = CGFloat(videoResolution.height / rows / videoAssetHeight)
                if factorHeight > factorWidth {
                    factor = factorWidth
                    Scale = CGAffineTransform(scaleX: factor, y: factor)
                    tx = 0
                    ty = (videoResolution.height / rows - videoAssetHeight * factor) / 2
                } else {
                    factor = factorHeight
                    Scale = CGAffineTransform(scaleX: factor, y: factor)
                    ty = 0
                    tx = (videoResolution.width / columns - videoAssetWidth * factor) / 2
                }
            }
            
            var orientation = CGAffineTransform.identity
            switch videoAssetOrientation_ {
            case .down:
                orientation = CGAffineTransform(rotationAngle: degreeToRadian(180))
                tx = (videoAssetWidth*factor) + CGFloat(tx)
                ty = (videoAssetHeight*factor) + CGFloat(ty)
            case .left:
                orientation = CGAffineTransform(rotationAngle: degreeToRadian(270))
                ty = (videoAssetHeight*factor) + CGFloat(ty)
            case .right:
                orientation = CGAffineTransform(rotationAngle: degreeToRadian(90))
                tx = (videoAssetWidth * factor) + CGFloat(tx)
            default:
                break;
            }
            
            let columnIndex = CGFloat(i % Int(columns))
            let rowIndex = CGFloat(i / Int(columns))
//            debugPrint("\(columnIndex) x \(rowIndex)")
            Move = CGAffineTransform(translationX: CGFloat((videoResolution.width / columns)*columnIndex) + tx, y: CGFloat((videoResolution.width / rows)*rowIndex) + ty)
            
            
            guard insertVideoWithTransform(isRepeatVideo, subInstruction, orientation.concatenating(Scale), Move, &arrAVMutableVideoCompositionLayerInstruction, asset, composition, completion, maxTime) else {
                return
            }
            
        }
        if isAudio {
            if let audioFileURL = audioFileURL {
                addAudioToMergedVideo(audioFileURL, composition, isRepeatAudio, maxTime, completion)
            } else {
                videoFileURLs.forEach { (audioFileURL) in
                    addAudioToMergedVideo(audioFileURL, composition, isRepeatAudio, maxTime, completion)
                }
            }
        }
        instruction.layerInstructions = arrAVMutableVideoCompositionLayerInstruction.reversed()

        exportMergedVideo([instruction], highestFrameRate, videoResolution, composition, videoQuality, completion)
        
    }

    
  
    
    /// Merge side by side videos layout
    /// - Parameters:
    ///   - videoFileURLs: Video file path URLs, Array  videos that going to parallel merge
    ///   - audioFileURL: Optional audio file for Merged Video
    ///   - videoResolution: Output video resolution
    ///   - isRepeatVideo: Repeat Video if one or more video have shorter duartion time then output video duration
    ///   - isRepeatAudio: Repeat Audio if Merged video have longer duartion time then provided Audio duration
    ///   - videoDuration: Output video duration (defult:  -1, find max duration from provided videos)
    ///   - videoQuality: AVAssetExportPresetMediumQuality(default) , AVAssetExportPresetLowQuality , AVAssetExportPresetHighestQuality
    ///   - alignment: Video merge alignment -1) vertical 2) horizontal (defult: vertical)
    ///   - completion: completion give  2 optional  values, 1)mergedVideoURL: URL path of successfully parallel merged video  2)error: gives Error object if some error occur in videos merging process
    ///   - mergedVideoURL: URL path of successfully parallel merged video
    ///   - error: gives Error object if some error occur in videos merging process
    @available(*, deprecated, message: "Use grid merge using matrix")
    open func parallelMergeVideos(withFileURLs
        videoFileURLs: [URL],
        audioFileURL: URL? = nil,
        videoResolution: CGSize,
        isRepeatVideo: Bool = false,
        isRepeatAudio: Bool = false,
        videoDuration: Int = -1,
        videoQuality: String = AVAssetExportPresetMediumQuality,
        alignment: ParallelMergeAlignment = .vertical,
        completion: @escaping (_ mergedVideoURL: URL?, _ error: Error?) -> Void) {
        
        var matrix: DPVideoMatrix!
        if alignment == .vertical {
            matrix = DPVideoMatrix(rows: 1, columns: UInt(videoFileURLs.count))
        } else {
            matrix = DPVideoMatrix(rows: UInt(videoFileURLs.count), columns: 1)
        }
       gridMergeVideos(withFileURLs: videoFileURLs, matrix: matrix, audioFileURL: audioFileURL, videoResolution: videoResolution, isRepeatVideo: isRepeatVideo, isRepeatAudio: isRepeatAudio, isAudio: true, videoDuration: videoDuration, videoQuality: videoQuality, completion: completion)
    }

}

// MARK:-  Private Functions
fileprivate extension DPVideoMerger {
    
    func generateMergedVideoFilePath() -> String {
        return URL(fileURLWithPath: ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last)?.path)!).appendingPathComponent("\(UUID().uuidString)-mergedVideo.mp4").path
    }
    func degreeToRadian(_ degree: CGFloat) -> CGFloat {
        return (.pi * degree / 180.0)
    }

    func maxTimeFromVideos(_ videoFileURLs : [URL]) -> CMTime {
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
        return maxTime
    }
    
    func videoAssetOrientation(_ videoAsset: AVAssetTrack) -> UIImage.Orientation {
        let videoTransform: CGAffineTransform = videoAsset.preferredTransform
        var videoAssetOrientation_: UIImage.Orientation = .up
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = .right
        } else if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = .left
        } else if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation_ = .up
        } else if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation_ = .down
        }
        return videoAssetOrientation_
    }
    
    func insertVideoWithTransform(_ isRepeatVideo: Bool, _ subInstruction: AVMutableVideoCompositionLayerInstruction, _ Scale: CGAffineTransform, _ Move: CGAffineTransform, _ arrAVMutableVideoCompositionLayerInstruction: inout [AVMutableVideoCompositionLayerInstruction], _ asset: AVURLAsset, _ composition: AVMutableComposition, _ completion: @escaping (URL?, Error?) -> Void, _ maxTime: CMTime) -> Bool {
        if (isRepeatVideo) {
            subInstruction.setTransform(Scale.concatenating(Move), at: .zero)
            arrAVMutableVideoCompositionLayerInstruction.append(subInstruction)
            
            var dur = asset.duration
            
            repeat {
                dur = CMTimeAdd(dur, asset.duration)
                let atTime = CMTimeSubtract(dur, asset.duration)
                guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    DispatchQueue.main.async { completion(nil,self.videoTarckError()) }
                    return false
                }
                if CMTimeCompare(maxTime, atTime) != 0 {
                    var vDuration : CMTime
                    if CMTimeCompare(maxTime, dur) == -1 {
                        let sub = CMTimeSubtract(dur, maxTime)
                        vDuration = CMTimeSubtract(asset.duration, sub)
                        
                    } else {
                        vDuration = asset.duration
                    }
                    do {
                        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: vDuration), of: asset.tracks(withMediaType: .video)[0], at: atTime)
                    } catch {
                        DispatchQueue.main.async { completion(nil,error) }
                        return false
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
        return true
    }
    
    func addAudioToMergedVideo(_ audioFileURL: URL?, _ composition: AVMutableComposition, _ isRepeatAudio : Bool , _ maxTime: CMTime, _ completion: @escaping (URL?, Error?) -> Void) {
        if let audioFileURL = audioFileURL {
            guard let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                DispatchQueue.main.async { completion(nil, self.audioTarckError()) }
                return
            }
            let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: audioFileURL, options: options)
            guard let audioAsset: AVAssetTrack = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async {completion(nil, self.audioTarckError()) }
                return
            }
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: maxTime.seconds < asset.duration.seconds ? maxTime : asset.duration), of: audioAsset, at: .zero)
            } catch {
                DispatchQueue.main.async { completion(nil,error) }
                return
            }
            if (isRepeatAudio && maxTime.seconds > asset.duration.seconds) {
                var dur = asset.duration
                repeat {
                    dur = CMTimeAdd(dur, asset.duration)
                    let atTime = CMTimeSubtract(dur, asset.duration)
                    if CMTimeCompare(maxTime, atTime) != 0 {
                        var aDuration : CMTime
                        if CMTimeCompare(maxTime, dur) == -1 {
                            let sub = CMTimeSubtract(dur, maxTime)
                            aDuration = CMTimeSubtract(asset.duration, sub)
                            
                        } else {
                            aDuration = asset.duration
                        }
                        do {
                            try audioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: aDuration), of: audioAsset, at: atTime)
                        } catch {
                            DispatchQueue.main.async { completion(nil,error) }
                            return
                        }
                    }
                    
                } while CMTimeCompare(maxTime, dur) != -1
            }
        }
    }
       
    
    func exportMergedVideo(_ instructions: [AVVideoCompositionInstructionProtocol], _ highestFrameRate: Int, _ videoResolution: CGSize, _ composition: AVMutableComposition, _ videoQuality: String, _ completion: @escaping (URL?, Error?) -> Void) {
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = instructions
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(highestFrameRate))
        mainComposition.renderSize = videoResolution
        
        let url = URL(fileURLWithPath: generateMergedVideoFilePath())
        
        let exporter = AVAssetExportSession(asset: composition, presetName: videoQuality)
        exporter?.outputURL = url
        exporter?.videoComposition = mainComposition
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = true
        
        debugPrint("Composition Duration: %ld s", lround(CMTimeGetSeconds(composition.duration)))
        debugPrint("Composition Framerate: %d fps", highestFrameRate)
        
        let exportCompletion: (() -> Void) = {() -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                completion(exporter?.outputURL, exporter?.error)
            })
        }
        if let exportSession = exporter {
            exportSession.exportAsynchronously(completionHandler: {() -> Void in
                switch exportSession.status {
                case .completed:
                    debugPrint("Successfully merged: %@", exportSession.outputURL ?? "")
                    exportCompletion()
                case .failed:
                    debugPrint("Failed %@",exportSession.error ?? "")
                    exportCompletion()
                case .cancelled:
                    debugPrint("Cancelled")
                    exportCompletion()
                case .unknown:
                    debugPrint("Unknown")
                case .exporting:
                    debugPrint("Exporting")
                case .waiting:
                    debugPrint("Wating")
                @unknown default:
                    debugPrint("default")
                }
            })
        }
    }
    
   
}

// MARK:-  Private Error Functions
fileprivate extension DPVideoMerger {
    
    func videoTarckError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Provide correct video file", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "No video track available", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    func audioTarckError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Video file had no Audio track", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "No Audio track available", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    func videoSizeError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "videoSize height/width should grater than equal to 100", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "videoSize too small", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    func videoCountError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Provide 4 Videos", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "gridMerge required 4 videos to merge", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    func videoDurationError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "videoDuration should grater than equal to logest video duration from all videoes.", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "videoDuration is small to complete videoes", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    
    func videoMoreThenOneError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Provide more then one Video", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "Video merge required more then one Video", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
    func gridMatrixError() -> Error {
        let userInfo: [AnyHashable : Any] =
            [ NSLocalizedDescriptionKey :  NSLocalizedString("error", value: "Grid matrix value error", comment: "") ,
              NSLocalizedFailureReasonErrorKey : NSLocalizedString("error", value: "Matrix rows or columns value should not be zero.", comment: "")]
        return NSError(domain: String(describing:DPVideoMerger.self), code: 404, userInfo: (userInfo as! [String : Any]))
    }
    
}
