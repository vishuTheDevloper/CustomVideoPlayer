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
    @IBOutlet weak var VideoControlView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    //MARK: Video View
    @IBOutlet weak var videoView: UIView!
    
    //MARK: Indicators
    @IBOutlet weak var loaderIndicator: UIActivityIndicatorView!
    
    //MARK: Player Class object
    var player:VideoPLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Initialize Video Player
        player = VideoPLayer(indicator: self.loaderIndicator, ControlView: VideoControlView)
        
        //MARK: Hide Control At Begining
        player.hideControl(after: 0.0)
        
        //MARK: Hide Inidicator When Stopped
        loaderIndicator.hidesWhenStopped = true
        
        //MARK: Add Tap Gesture On Video Control View
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleVideoControlTap(_:)))
        VideoControlView.addGestureRecognizer(tap)
        VideoControlView.tag = 1
        
    }
    
    
    @objc func handleVideoControlTap(_ sender: UITapGestureRecognizer? = nil) {
        self.VideoControlView.tag = self.VideoControlView.tag == 0 ? 1 : 0
        if  self.VideoControlView.tag == 0{
            player.showControl(after: 0.0)
        }
        else{
            player.hideControl(after: 0.0)
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
            self.player.playerLayer?.frame = self.VideoControlView.bounds
        }
    }
}

