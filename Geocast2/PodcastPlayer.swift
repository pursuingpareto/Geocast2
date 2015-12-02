//
//  PodcastPlayer.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation

class PodcastPlayer: NSObject {
    
    private var currentEpisode: Episode?
    private var player: AVPlayer = AVPlayer()
    private var onItemReady: () -> Void = {}
    
    class var sharedInstance: PodcastPlayer {
        struct Singleton {
            static let instance = PodcastPlayer()
        }
        return Singleton.instance
    }
    
    func loadEpisode(episode: Episode, withUserEpisodeData data: UserEpisodeData?, completion: () -> Void) {
        if let currentEp = currentEpisode {
            if currentEp == episode {
                // no need to do anything
                return
            }
        }
        currentEpisode = episode
        print("currentEpisode is \(currentEpisode!.title)")
        let url = currentEpisode!.mp3URL
        print("mp3URL is at \(url.path)")
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            let playerItem = AVPlayerItem(URL: url)
            self.loadItem(playerItem)
            self.onItemReady = completion
            dispatch_async(dispatch_get_main_queue(), {
                if let data = data {
                    self.player.seekToTime(data.lastPlayedTimestamp)
                }
            })
        }
    }
    
    private func loadItem(playerItem: AVPlayerItem) {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: .New, context: &playerItemStatusContext)
        print("playerItemStatusIs \(playerItem.status.rawValue)")
    }
    
    func play() {
        guard readyToPlay() else {
            print("cannot play now")
            return
        }
        player.play()
    }
    
    func pause() {
        guard readyToPlay() else {
            print("cannot pause now")
            return
        }
        player.pause()
    }
    
    func seekToTime(time: CMTime) {
        if readyToPlay() {
            player.seekToTime(time)
        }
    }
    
    func fastForwardBy(time: CMTime) {
        seekToTime(player.currentTime() + time)
    }
    
    func rewindBy(time: CMTime) {
        seekToTime(player.currentTime() - time)
    }
    
    private func readyToPlay() -> Bool {
        if player.status == .ReadyToPlay {
            if player.currentItem?.status == .ReadyToPlay {
                return true
            } else {
                print("player item status is \(player.currentItem?.status.rawValue)")
                return false
            }
        } else {
            print("player status is \(player.status.rawValue)")
            return false
        }
    }
    
    private var playerItemStatusContext = 0
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("OBSERVING VALUE FOR KEY PATH \(keyPath)")
        if context == &playerItemStatusContext {
            print("change is \(change?[NSKeyValueChangeNewKey])")
            if let status = player.currentItem?.status {
                switch status {
                case .ReadyToPlay:
                    onItemReady()
                case .Failed:
                    print("loading failed")
                case .Unknown:
                    print("status unknown")
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
    }
    
//    private func periodicallyCheckPlayerItem(item: AVPlayerItem, withInterval interval: Float, duration: CMTime) {
//        let timer = NSTimer(timeInterval: <#T##NSTimeInterval#>, target: <#T##AnyObject#>, selector: <#T##Selector#>, userInfo: <#T##AnyObject?#>, repeats: <#T##Bool#>)
//    }
    
}