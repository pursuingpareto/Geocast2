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

let newEpisodeLoadedNotificationKey = "com.andybrown.newEpisodeLoadedKey"
let playRateChangedNotificationKey = "com.andybrown.playRateChangedKey"
let playerItemStatusChangedNotificationKey = "com.andybrown.playerItemStatusChangedKey"
let playTimerUpdateNotificationKey = "com.andybrown.playTimerUpdateKey"

class PodcastPlayer: UIResponder {
    
    var fastForwardAmount = CMTimeMake(15, 1)
    var rewindAmount = CMTimeMake(15, 1)
    
    var currentItemStatus: AVPlayerItemStatus {
        return ((player.currentItem) != nil) ? player.currentItem!.status : AVPlayerItemStatus.Unknown
    }
    var currentPlayTime: CMTime? {
        return player.currentTime()
    }
    var duration: CMTime?
    var isPlaying: Bool { return (player.rate > 0) }
    
    private var currentEpisode: Episode? = nil
    private var player: AVPlayer = AVPlayer()
    private var onItemReady: () -> Void = {}
    private var playTimer: NSTimer?
    
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
    
    func getCurrentEpisode() -> Episode? { return currentEpisode }
    
    func play() {
        guard readyToPlay() else {
            print("cannot play now")
            return
        }
        player.play()
        NSNotificationCenter.defaultCenter().postNotificationName(playRateChangedNotificationKey, object: self)
        playTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "updateTime", userInfo: nil, repeats: true)
    }
    
    func pause() {
        guard readyToPlay() else {
            print("cannot pause now")
            return
        }
        print("about to pause")
        player.pause()
        playTimer?.invalidate()
    }
    
    func updateTime() {
        NSNotificationCenter.defaultCenter().postNotificationName(playTimerUpdateNotificationKey, object: self)
        guard let episode = getCurrentEpisode() else {
            return
        }
        guard let totalSeconds = player.currentItem?.duration.seconds else {
            return
        }
        var songInfo: [String: AnyObject] = [
            MPMediaItemPropertyArtist: episode.podcast.title,
            MPMediaItemPropertyTitle: episode.title,
            MPMediaItemPropertyPlaybackDuration: totalSeconds,
            //                MPMediaItemPropertyArtwork: podcastArt,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPNowPlayingInfoPropertyPlaybackRate: self.player.rate
        ]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [String : AnyObject]
    }
    
    func seekToTime(time: CMTime) {
        if readyToPlay() {
            player.seekToTime(time, completionHandler: {_ in 
                self.updateTime()
            })
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
            duration = player.currentItem?.duration
            setupRemoteControl(withItem: player.currentItem)
            NSNotificationCenter.defaultCenter().postNotificationName(playerItemStatusChangedNotificationKey, object: self)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
    }
    
    private func loadItem(playerItem: AVPlayerItem) {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemStatusContext)
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: .New, context: &playerItemStatusContext)
        print("playerItemStatusIs \(playerItem.status.rawValue)")
    }
    
    func setupRemoteControl(withItem item: AVPlayerItem?) {
//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        if item == nil || item?.status != .ReadyToPlay {
            return
        }
        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
//            let podcastArt = MPMediaItemArtwork(image: image!)
            guard let episode = getCurrentEpisode() else {
                return
            }
            guard let totalSeconds = item?.duration.seconds else {
                return
            }
            var songInfo: [String: AnyObject] = [
                MPMediaItemPropertyArtist: episode.podcast.title,
                MPMediaItemPropertyTitle: episode.title,
                MPMediaItemPropertyPlaybackDuration: totalSeconds,
//                MPMediaItemPropertyArtwork: podcastArt,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
                MPNowPlayingInfoPropertyPlaybackRate: self.player.rate
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [String : AnyObject]
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("block done")
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