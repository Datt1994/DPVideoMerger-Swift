//
//  ViewController.swift
//  DPVideoMerger
//
//  Created by datt on 14/02/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnMergeVideoAction(_ sender: UIButton) {
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        view.isUserInteractionEnabled = false
        let fileURL = Bundle.main.url(forResource: "1", withExtension: "mp4")
        let fileURL1 = Bundle.main.url(forResource: "2", withExtension: "mp4")
        let fileURL2 = Bundle.main.url(forResource: "3", withExtension: "MOV")
        let fileURL3 = Bundle.main.url(forResource: "4", withExtension: "mp4")
        let fileURLs = [fileURL, fileURL1, fileURL2, fileURL3]
        
        DPVideoMerger().mergeVideos(withFileURLs: fileURLs as! [URL], completion: {(_ mergedVideoFile: URL?, _ error: Error?) -> Void in
            self.activityIndicatorView.stopAnimating()
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView.isHidden = true
            if error != nil {
                let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
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
    
}

