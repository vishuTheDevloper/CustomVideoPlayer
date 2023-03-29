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
    var CurrenttimeLabel:UILabel
    var totalTime:UILabel
    var playButton:UIButton
    var isFinished:Bool = false
    init(indicator: UIActivityIndicatorView,ControlView:UIView,seekBar:UISlider,currentTimeLabel:UILabel,TotalTimeLabel:UILabel,playButton:UIButton) {
        self.indicator = indicator
        self.videoControlView = ControlView
        self.seekBar = seekBar
        self.CurrenttimeLabel = currentTimeLabel
        self.totalTime = TotalTimeLabel
        self.playButton = playButton
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
        
        //MARK: Observers For Player To detect Its State
        playerItem?.addObserver(self, forKeyPath: "status", options: [.initial, .new], context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        
        
         timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: DispatchQueue.main) { [weak self] time in
             self?.runOnMainThread {
                 self?.seekBar.value = Float(time.seconds)
                  self?.CurrenttimeLabel.text = self?.formatDuration(seconds: TimeInterval(floatLiteral: time.seconds))
             }
        }
        
        player?.play()
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        let time = CMTime(seconds: Double(slider.value), preferredTimescale: 1000)
        player?.seek(to: time)
        runOnMainThread {
            self.CurrenttimeLabel.text = self.formatDuration(seconds: TimeInterval(floatLiteral: time.seconds))
        }
       
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
                runOnMainThread {
                    self.seekBar.maximumValue = Float(self.duration ?? 0.0)
                    self.totalTime.text = self.formatDuration(seconds: TimeInterval(floatLiteral: self.duration ?? 0.0))
                }
                NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
                hideLoader()
            
            @unknown default:
                fatalError("Unknown player item status")
            }
            
            
            
        }
        if object is AVPlayerItem {
             switch keyPath {
                 case "playbackBufferEmpty":
                 showLoader()

                 case "playbackLikelyToKeepUp":
                 hideLoader()
                 

                 case "playbackBufferFull":
                hideLoader()
             case .none:
                print("do nothing")
             case .some(_):
                 print("do nothing")
             }
         }
        
        
        
    }
    
    
    @objc func videoDidFinishPlaying(note: NSNotification) {
       print("Video is Finished")
        runOnMainThread {
            self.seekBar.value = Float(0.0)
            self.CurrenttimeLabel.text = "00:00"
            self.player?.pause()
            let image = UIImage(systemName: "play.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            self.playButton.setImage(image, for: .normal)
            self.isFinished = true
        }
        showControl(after: 0.0)
    }
    

    
    //MARK: Loader
    func showLoader() {
        runOnMainThread {
            self.playButton.isHidden = true
            self.indicator.startAnimating()
        }
    }
    
    func hideLoader() {
        runOnMainThread {
            self.playButton.isHidden = false
            self.indicator.stopAnimating()
        }
        hideControl(after: 3.0)
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
    
    func hideButton(after time:Double){
        
        if self.hideControlsTask != nil { cancelHideControlsTask()}
        hideControlsTask = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.playButton.isHidden = true
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
      
        if isFinished{
            runOnMainThread {
                self.isFinished = false
                self.player?.seek(to: CMTime.zero)
                let image = UIImage(systemName: "pause.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                button.setImage(image, for: .normal)
            }
            self.hideControl(after: 3.0)
            player?.play()
        }
        else{
            if player?.rate == 0 {
                runOnMainThread {
                    let image = UIImage(systemName: "pause.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                    button.setImage(image, for: .normal)
                }
                self.hideControl(after: 3.0)
                player?.play()
            } else {
                runOnMainThread {
                    let image = UIImage(systemName: "play.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                    button.setImage(image, for: .normal)
                }
                player?.pause()
                //hideControl(after: 3.0)
            }
        }
     
    }

    
    func formatDuration(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
//        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: seconds)!
    }
    
    
    func runOnMainThread(_ closure: @escaping () -> Void) {
        DispatchQueue.main.async {
            closure()
        }
    }
}


