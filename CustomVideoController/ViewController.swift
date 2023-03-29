//
//  ViewController.swift
//  CustomVideoController
//
//  Created by John on 29/03/23.
//

import UIKit
import AVKit
import AVFoundation
class ViewController: UIViewController {
    
    //MARK: Video Control Outlets
    @IBOutlet weak var backWardImage: UIImageView!
    @IBOutlet weak var forwardImage: UIImageView!
    @IBOutlet weak var VideoControlView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var seekBar: UISlider!
    @IBOutlet weak var totalTimeLAbel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    //MARK: Video View
    @IBOutlet weak var videoView: UIView!
    
    //MARK: Indicators
    @IBOutlet weak var loaderIndicator: UIActivityIndicatorView!
    
    //MARK: Player Class object
    var player:VideoPLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backWardImage.alpha = 0.0
        forwardImage.alpha = 0.0
        //MARK: Initialize Video Player
        player = VideoPLayer(indicator: self.loaderIndicator, ControlView: VideoControlView,seekBar: self.seekBar,currentTimeLabel: self.currentTimeLabel,TotalTimeLabel: self.totalTimeLAbel,playButton: self.playButton)
        
//        //MARK: Hide Control At Begining
//        player.hideControl(after: 0.0)
        
        //MARK: Hide Inidicator When Stopped
        loaderIndicator.hidesWhenStopped = true
        
        //MARK: Add Tap Gesture On Video Control View
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleVideoControlTap(_:)))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        
        VideoControlView.addGestureRecognizer(tap)
        VideoControlView.tag = 1
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.handleVideoControlTapDouble(_:)))
        tap2.numberOfTapsRequired = 2
       
        VideoControlView.addGestureRecognizer(tap2)
        tap.require(toFail: tap2)
        
    }
    
    
    @objc func handleVideoControlTap(_ sender: UITapGestureRecognizer? = nil) {
        print("single tap")
        self.VideoControlView.tag = self.VideoControlView.tag == 0 ? 1 : 0
        if  self.VideoControlView.tag == 0{
            player.showControl(after: 0.0)
        }
        else{
            player.hideControl(after: 0.0)
        }
    }
    
    
    @objc func handleVideoControlTapDouble(_ sender: UITapGestureRecognizer? = nil) {
      print("double tap Gesture")
        self.VideoControlView.tag = 0
        player.showControl(after: 0.0)
        let tapLocation = sender?.location(in: view)
          let screenWidth = view.bounds.width
          
        if let tapLoc = tapLocation?.x{
            if tapLoc < screenWidth / 2 {
                  // Double tap on left side of screen
                print("left side")
                if let playr = player.player{
                    let currentTime = playr.currentTime()
                          let targetTime = max(currentTime - CMTime(seconds: 10, preferredTimescale: 1000), CMTime.zero)
                          playr.seek(to: targetTime)
                    UIView.animate(withDuration: 0.5, animations: {
                        self.backWardImage.alpha = 1.0
                    }) { (finished) in
                        // Hide the image with a fade-out animation after a delay of 1 second
                        UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                            self.backWardImage.alpha = 0.0
                        })
                    }
                    
                }
              }
            
            else {
                  print("right side")
                  if let playr = player.player{
                      let currentTime = playr.currentTime()
                             let duration = playr.currentItem?.duration ?? CMTime.zero
                             let targetTime = min(currentTime + CMTime(seconds: 10, preferredTimescale: 1), duration)
                      playr.seek(to: targetTime)
                      UIView.animate(withDuration: 0.5, animations: {
                          self.forwardImage.alpha = 1.0
                      }) { (finished) in
                          UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                              self.forwardImage.alpha = 0.0
                          })
                      }
                  }
              }
        }
        
       
    }
    
    func playVideo(){
        let url = URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!
        player.play(url: url, view: videoView)
    }

    
    override func viewWillAppear(_ animated: Bool) {
      playVideo()
    }
    
    
    @IBAction func actionPLayButton(_ sender: UIButton) {
        player.playButtonTapped(button: sender)
    }
    
    //MARK: It Is Used To Handle the Layer In All Orientaion
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.player.playerLayer?.frame = self.videoView.bounds
        }
    }
}

