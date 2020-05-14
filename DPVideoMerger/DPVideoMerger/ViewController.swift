//
//  ViewController.swift
//  DPVideoMerger
//
//  Created by datt on 14/02/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit
import AVKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var arrImgAssets: [PHAsset] = []
    var imageManager = PHCachingImageManager()
    var arrIndex: [IndexPath] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true
        
        arrIndex = [IndexPath]()
        let results = PHAsset.fetchAssets(with: .video, options: nil)
        arrImgAssets = [PHAsset]()
        
        results.enumerateObjects({ obj, idx, stop in
            self.arrImgAssets.append(obj)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnMergeVideoAction(_ sender: UIButton) {
        if arrIndex.count == 0 {
            print("please select video")
            return
        }
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        view.isUserInteractionEnabled = false
        //        let fileURL = Bundle.main.url(forResource: "1", withExtension: "mp4")
        //        let fileURL1 = Bundle.main.url(forResource: "2", withExtension: "mp4")
        //        let fileURL2 = Bundle.main.url(forResource: "3", withExtension: "MOV")
        //        let fileURL3 = Bundle.main.url(forResource: "4", withExtension: "mp4")
        //        let fileURLs = [fileURL, fileURL1, fileURL2, fileURL3]
        var fileURLs = [URL]()
        //        arrIndex.enumerateObjects({ indexPath, idx, stop in
        for indexPath in arrIndex {
            let object = self.arrImgAssets[indexPath.row]
            self.imageManager.requestAVAsset(forVideo: object, options: nil, resultHandler: { asset, audioMix, info in
                let url = ((asset as? AVURLAsset)?.url)?.standardizedFileURL
                //                    if let url = url {
                //                        print("\(url)")
                //                    }
                //                    print("url = \(url?.absoluteString ?? "")")
                //                    print("url = \(url?.relativePath ?? "")")
                if let url = url {
                    fileURLs.append(url)
                }
                if fileURLs.count == self.arrIndex.count {
                    DPVideoMerger().mergeVideos(withFileURLs: fileURLs,videoQuality:AVAssetExportPresetHighestQuality ,completion: {(_ mergedVideoFile: URL?, _ error: Error?) -> Void in
                        self.activityIndicatorView.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        self.activityIndicatorView.isHidden = true
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
                }
            })
        }
        
    }
    
    @IBAction func btnGridMergeVideoAction(_ sender: UIButton) {
        if arrIndex.count == 0 {
            print("please select video")
            return
        }
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        view.isUserInteractionEnabled = false
        //        let fileURL = Bundle.main.url(forResource: "1", withExtension: "mp4")
        //        let fileURL1 = Bundle.main.url(forResource: "2", withExtension: "mp4")
        //        let fileURL2 = Bundle.main.url(forResource: "3", withExtension: "MOV")
        //        let fileURL3 = Bundle.main.url(forResource: "4", withExtension: "mp4")
        //        let fileURLs = [fileURL, fileURL1, fileURL2, fileURL3]
        var fileURLs = [URL]()
        //        arrIndex.enumerateObjects({ indexPath, idx, stop in
        for indexPath in arrIndex {
            let object = self.arrImgAssets[indexPath.row]
            self.imageManager.requestAVAsset(forVideo: object, options: nil, resultHandler: { asset, audioMix, info in
                let url = ((asset as? AVURLAsset)?.url)?.standardizedFileURL
                //                        if let url = url {
                //                            print("\(url)")
                //                        }
                //                        print("url = \(url?.absoluteString ?? "")")
                //                        print("url = \(url?.relativePath ?? "")")
                if let url = url {
                    fileURLs.append(url)
                }
                if fileURLs.count == self.arrIndex.count {
                    DPVideoMerger().gridMergeVideos(withFileURLs: fileURLs, videoResolution: CGSize(width: 1000, height: 1000),isRepeatVideo: true, videoQuality:AVAssetExportPresetHighestQuality ,completion: {(_ mergedVideoFile: URL?, _ error: Error?) -> Void in
                        self.activityIndicatorView.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        self.activityIndicatorView.isHidden = true
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
                }
            })
        }
        
    }
    
}

extension ViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrImgAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoImgCell", for: indexPath) as! VideoImgCell
        let object = arrImgAssets[indexPath.row]
        imageManager.requestImage(for: object, targetSize: CGSize(width: collectionView.frame.width/2 - 10, height: collectionView.frame.width/2 - 10), contentMode: .aspectFit, options: nil, resultHandler: { result, info in
            cell.img.image = result
        })
        return cell ;
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? VideoImgCell
        cell?.img.alpha = 1
        if arrIndex.contains(indexPath) {
            arrIndex.removeAll(where: { element in element == indexPath })
        } else {
            arrIndex.append(indexPath)
            cell?.img.alpha = 0.5
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/2 - 10, height: collectionView.frame.width/2 - 10)
    }
    
}
class VideoImgCell: UICollectionViewCell {
    @IBOutlet weak var img: UIImageView!
    
}
