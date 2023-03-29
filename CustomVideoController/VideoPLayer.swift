//
//  VideoPLayer.swift
//  CustomVideoController
//
//  Created by John on 29/03/23.
//

import Foundation
import AVKit
import AVFoundation
import UIKit
class VideoPLayer:NSObject{
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var indicator:UIActivityIndicatorView
    var videoControlView:UIView
    var hideControlsTask: DispatchWorkItem?
    var playerLayer:AVPlayerLayer?
    var duration:Double?
    var seekBar:UISlider
    var CurrenttimeLabel:UILabel?
    var totalTime:UILabel?
    init(indicator: UIActivityIndicatorView,ControlView:UIView,seekBar:UISlider) {
        self.indicator = indicator
        self.videoControlView = ControlView
        self.seekBar = seekBar
      
    }
    var timeObserver:Any?
    
    //MARK: Setup and play video
    
    func play(url:URL,view:UIView){
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        self.playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer?.zPosition = -1
        view.layer.addSublayer(playerLayer!)
        self.seekBar.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        playerItem?.addObserver(self, forKeyPath: "status", options: [.initial, .new], context: nil)
        
         timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
            self?.seekBar.value = Float(time.seconds)
        }
        
        player?.play()
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        let time = CMTime(seconds: Double(slider.value), preferredTimescale: 1)
        player?.seek(to: time)
    }
    
    
    //MARK: Handle Status of Video
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let item = object as? AVPlayerItem {
            switch item.status {
            case .failed:
                print("Player item failed to load")
                handleErrorWithMessage(player?.currentItem?.error?.localizedDescription, error:player?.currentItem?.error)
            case .unknown:
                showLoader()
            case .readyToPlay:
                duration = playerItem?.duration.seconds
                seekBar.maximumValue = Float(duration ?? 0.0)
                hideLoader()
            @unknown default:
                fatalError("Unknown player item status")
            }
        }
    }
    
    //MARK: Loader
    func showLoader() {
        indicator.startAnimating()
    }
    
    func hideLoader() {
        indicator.stopAnimating()
    }
    
    
    
    
    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        print("Error occured with message: \(String(describing: message)), error: \(String(describing: error)).")
    }
    
    
    //MARK: Show Hide Controls
    
    func hideControl(after time:Double){
        
        if self.hideControlsTask != nil { cancelHideControlsTask()}
        hideControlsTask = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            for subview in weakSelf.videoControlView.subviews {
                subview.isHidden = true
            }
            weakSelf.videoControlView.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: hideControlsTask!)
    }
    
    func showControl(after time:Double){
        if self.hideControlsTask != nil { cancelHideControlsTask()}
        hideControlsTask = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            for subview in weakSelf.videoControlView.subviews {
                subview.isHidden = false
            }
            weakSelf.videoControlView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: hideControlsTask!)
    }
    
    
    //MARK: Cancel Previous Task
    func cancelHideControlsTask() {
        hideControlsTask?.cancel()
    }
    
    //MARK: Play Button Tapped
    func playButtonTapped(button:UIButton) {
        if player?.rate == 0 {
            player?.play()
            let image = UIImage(systemName: "pause.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            button.setImage(image, for: .normal)
            hideControl(after: 3.0)
        } else {
            player?.pause()
            let image = UIImage(systemName: "play.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            button.setImage(image, for: .normal)
            //hideControl(after: 3.0)
        }
    }

    
    
}
