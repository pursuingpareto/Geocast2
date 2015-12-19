//
//  PodcastPlayer.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Kingfisher

let newEpisodeLoadedNotificationKey = "com.andybrown.newEpisodeLoadedKey"
let playRateChangedNotificationKey = "com.andybrown.playRateChangedKey"
let playerItemStatusChangedNotificationKey = "com.andybrown.playerItemStatusChangedKey"
let playTimerUpdateNotificationKey = "com.andybrown.playTimerUpdateKey"
let applicationBecameActiveNotificationKey = "com.andybrown.applicationBecameActiveKey"


class PodcastPlayer: UIResponder {
    private var albumArt: MPMediaItemArtwork? = nil
    var fastForwardAmount = CMTimeMake(15, 1)
    var rewindAmount = CMTimeMake(15, 1)
    
    var currentItemStatus: AVPlayerItemStatus {
        return ((player.currentItem) != nil) ? player.currentItem!.status : AVPlayerItemStatus.Unknown
    }
    var currentPlayTime: CMTime? {
        return player.currentTime()
    }
    var duration: CMTime?
    var isPlaying: Bool { return (player.rate > 0.01 && (player.error == nil)) }
    
    private var currentEpisode: Episode? = nil
    private var player: AVPlayer = AVPlayer()
    private var onItemReady: () -> Void = {}
    private var playTimer: NSTimer?
    
    var timerUpdateIncrement = NSTimeInterval(1.0)
    
    class var sharedInstance: PodcastPlayer {
        struct Singleton {
            static let instance = PodcastPlayer()
        }
        return Singleton.instance
    }
    
    func loadEpisode(episode: Episode, withUserEpisodeData data: UserEpisodeData?, completion: () -> Void) {
        if let currentEp = currentEpisode {
            if currentEp == episode {
                // TODO : fix this... need to incorporate user data
                return
            }
        }
        currentEpisode = episode
        NSNotificationCenter.defaultCenter().postNotificationName(newEpisodeLoadedNotificationKey, object: self)
        print("currentEpisode is \(currentEpisode!.title)")
        let url = currentEpisode!.mp3URL
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
    
    func getCurrentEpisode() -> Episode? { return currentEpisode }
    
    func play() {
        guard readyToPlay() else {
            print("cannot play now")
            return
        }
        player.play()
        NSNotificationCenter.defaultCenter().postNotificationName(playRateChangedNotificationKey, object: self)
        playTimer = NSTimer.scheduledTimerWithTimeInterval(timerUpdateIncrement, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        updateNowPlaying()
    }
    
    func pause() {
        guard readyToPlay() else {
            print("cannot pause now")
            return
        }
        player.pause()
        playTimer?.invalidate()
        updateNowPlaying()
    }
    
    func updateTime() {
        NSNotificationCenter.defaultCenter().postNotificationName(playTimerUpdateNotificationKey, object: self)
        guard let episode = getCurrentEpisode() else {
            return
        }
        guard let totalSeconds = player.currentItem?.duration.seconds else {
            return
        }
        guard let elapsedSeconds = player.currentItem?.currentTime().seconds else {
            return
        }
        
        if let info = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            let lockedRate = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] as! Float
            if player.rate != lockedRate {
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedSeconds
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            }
        }
    }
    
    private func updateNowPlaying() {
        guard let episode = getCurrentEpisode() else {
            return
        }
        guard let totalSeconds = player.currentItem?.duration.seconds else {
            return
        }
        guard let elapsedSeconds = player.currentItem?.currentTime().seconds else {
            return
        }
        
        if let info = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedSeconds
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            if MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPMediaItemPropertyArtwork] == nil {
                if albumArt != nil {
                    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPMediaItemPropertyArtwork] = albumArt
                } else {
                    if let url = episode.podcast.largeImageURL {
                        print("got largeImageURL")
                        let cache = KingfisherManager.sharedManager.cache
                        cache.retrieveImageForKey(url.absoluteString, options: KingfisherManager.OptionsNone, completionHandler: {
                            (image, cacheType) -> () in
                            if let image = image {
                                print("assigning artwork")
                                self.albumArt = MPMediaItemArtwork(image: image)
                                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?[MPMediaItemPropertyArtwork] = self.albumArt
                            } else {
                                print("error assigning artwork")
                            }
                        })
                    }
                }
            }
        }
        
        
    }
    
    func seekToTime(time: CMTime) {
        let oldRate = player.rate
        if readyToPlay() {
            player.seekToTime(time, completionHandler: {_ in
                self.player.rate = oldRate
                self.updateTime()
                self.updateNowPlaying()
            })
        }
    }
    
    func fastForwardBy(time: CMTime) {
        seekToTime(player.currentTime() + time)
        updateNowPlaying()
    }
    
    func rewindBy(time: CMTime) {
        seekToTime(player.currentTime() - time)
        updateNowPlaying()
    }
    
    private func readyToPlay() -> Bool {
        if player.status == .ReadyToPlay {
            if player.currentItem?.status == .ReadyToPlay {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    private var playerItemStatusContext = 0
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &playerItemStatusContext {
            duration = player.currentItem?.duration
            setupRemoteControl(withItem: player.currentItem)
            NSNotificationCenter.defaultCenter().postNotificationName(playerItemStatusChangedNotificationKey, object: self)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
    }
    
    private func loadItem(playerItem: AVPlayerItem) {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: .New, context: &playerItemStatusContext)
        
    }
    
    func setupRemoteControl(withItem item: AVPlayerItem?) {
        print("setting up remoteControl with item \(item)")
        if item == nil || item?.status != .ReadyToPlay {
            return
        }
        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
            guard let episode = getCurrentEpisode() else {
                return
            }
            guard let totalSeconds = item?.duration.seconds else {
                return
            }
            guard let elapsedSeconds = item?.currentTime().seconds else {
                return
            }
            let songInfo: [String: AnyObject] = [
                MPMediaItemPropertyArtist: episode.podcast.title,
                MPMediaItemPropertyTitle: episode.title,
                MPMediaItemPropertyPlaybackDuration: totalSeconds,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedSeconds,
                MPNowPlayingInfoPropertyPlaybackRate: self.player.rate
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [String : AnyObject]
            
            if let url = episode.podcast.largeImageURL {
                print("got largeImageURL")
                let cache = KingfisherManager.sharedManager.cache
                cache.retrieveImageForKey(url.absoluteString, options: KingfisherManager.OptionsNone, completionHandler: {
                    (image, cacheType) -> () in
                    if let image = image {
                        print("assigning artwork")
                        self.albumArt = MPMediaItemArtwork(image: image)
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?[MPMediaItemPropertyArtwork] = self.albumArt
                    } else {
                        print("error assigning artwork")
                    }
                })
            }
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print("Audio session error.")
        }
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
//        let podcastArt = MPMediaItemArtwork(image: image!)
        if event?.type == UIEventType.RemoteControl {
            guard let subtype = event?.subtype else {
                return
            }
            switch subtype {
            case .RemoteControlPlay:
                play()
            case .RemoteControlPause:
                pause()
            case .RemoteControlNextTrack:
                fastForwardBy(fastForwardAmount)
            case .RemoteControlPreviousTrack:
                rewindBy(rewindAmount)
            case .RemoteControlTogglePlayPause:
                isPlaying ? pause() : play()
            default:
                return
            }
        }
    }


    
    
}