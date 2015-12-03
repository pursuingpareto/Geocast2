//
//  PlayerVC.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/1/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    enum ReadinessState: Int {
        case NoData = 0
        case Loading = 1
        case Normal = 2
    }
    
    @IBOutlet private weak var playedTime: UILabel!
    @IBOutlet private weak var remainingTime: UILabel!
    @IBOutlet private weak var progressBar: UISlider!
    @IBOutlet private weak var trackTitle: UILabel!
    @IBOutlet private weak var podcastTitle: UILabel!
    @IBOutlet private weak var pubDate: UILabel!
    @IBOutlet private weak var playButton: UIBarButtonItem!
    @IBOutlet private weak var playbackToolbar: UIToolbar!
    
    private var player = PodcastPlayer.sharedInstance
    private var fastForwardAmount = CMTimeMake(15, 1)
    private var rewindAmount = CMTimeMake(15, 1)
    
    private let addTagSegueIdentifier = "addTagSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressBar()
        setupListeners()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareView(forReadinessState: getCurrentReadinessState())
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == addTagSegueIdentifier {
            let tagVC = segue.destinationViewController as! AddTagViewController
            if let episode = player.getCurrentEpisode() {
                tagVC.episode = episode
            } else {
                return
            }
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    func prepareView(forReadinessState readinessState: ReadinessState) {
        switch readinessState {
        case .NoData:
            prepareNoDataView()
        case .Loading:
            prepareViewWithData()
            prepareLoadingView()
        case .Normal:
            prepareViewWithData()
            prepareNormalView()
        }
    }
    
    private func getCurrentReadinessState() -> ReadinessState {
        if player.getCurrentEpisode() == nil {
            return .NoData
        } else if player.currentItemStatus != .ReadyToPlay {
            return .Loading
        } else {
            return .Normal
        }
    }
    
    private func setupListeners() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newEpisodeLoaded", name: newEpisodeLoadedNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateToolbar", name: playRateChangedNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemStatusChanged", name: playerItemStatusChangedNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTime", name: playTimerUpdateNotificationKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func setupProgressBar() {
        let verticalBar = UIImage(named: "vertical_bar")
        let size = CGSizeApplyAffineTransform((verticalBar?.size)!, CGAffineTransformMakeScale(0.15, 0.15))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        verticalBar!.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledBar = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        progressBar.setThumbImage(scaledBar, forState: .Normal)
    }
    
    private func prepareNoDataView() {
        tabBarController?.tabBar.hidden = false
        for sv in view.subviews {
            sv.hidden = true
        }
    }
    
    private func prepareLoadingView() {

    }
    
    private func prepareNormalView() {
        

    }
    
    private func prepareViewWithData() {
        tabBarController?.tabBar.hidden = true
        for sv in view.subviews {
            sv.hidden = false
        }
        if let ep = player.getCurrentEpisode() {
            trackTitle.text = ep.title
            podcastTitle.text = ep.podcast.title
            pubDate.text = ({
                if ep.pubDate != nil {
                    let formatter = NSDateFormatter()
                    formatter.dateStyle = .MediumStyle
                    formatter.timeStyle = .ShortStyle
                    return formatter.stringFromDate(ep.pubDate!)
                } else {
                    return ""
                }})()
            progressBar.value = 0.0
            remainingTime.text = "00:00"
            playedTime.text = "00:00"
        }
        updateToolbar()
    }
    
    func playerItemStatusChanged() {
        if getCurrentReadinessState() == .Normal {
            player.play()
        }
        updateEnabledStatesOfView()
    }
    
    private func updateEnabledStatesOfView() {
        if getCurrentReadinessState() == .Normal {
            progressBar.userInteractionEnabled = true
            for btn in playbackToolbar.items! {
                btn.enabled = true
            }
        } else {
            progressBar.userInteractionEnabled = false
            for btn in playbackToolbar.items! {
                btn.enabled = false
            }
        }
    }
    
    func newEpisodeLoaded() {
        prepareView(forReadinessState: getCurrentReadinessState())
    }

    func updateTime() {
        print("updating time for vc")
        if let playTime = player.currentPlayTime {
            print(playTime.asString())
            playedTime.text = playTime.asString()
            if let duration = player.duration {
                remainingTime.text = (duration - playTime).asString()
                let progress = playTime.seconds / duration.seconds
                progressBar.value = Float(progress)
            }
            
        }
    }
    
    func updateToolbar() {
        var btn: UIBarButtonItem!
        if player.isPlaying {
            btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: "playPausePressed:")
        } else {
            btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: "playPausePressed:")
        }
        var items = playbackToolbar.items!
        items[3] = btn
        playbackToolbar.setItems(items, animated: false)
        updateEnabledStatesOfView()
    }
    
    @IBAction private func playPausePressed(sender: AnyObject?) {
        player.isPlaying ? player.pause() : player.play()
        updateToolbar()
    }
    
    @IBAction private func fastForwardPressed(sender: AnyObject) {
        player.fastForwardBy(fastForwardAmount)
    }
    
    @IBAction private func rewindPressed(sender: AnyObject) {
        player.rewindBy(rewindAmount)
    }
    
    @IBAction func hideButtonPressed(sender: AnyObject) {
        self.tabBarController?.selectedIndex = MainTabController.TabIndex.podcastIndex.rawValue
        self.tabBarController?.tabBar.hidden = false
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController()
        if let episode = player.getCurrentEpisode() {
            var subscribeAction: UIAlertAction!
            if !User.sharedInstance.isSubscribedTo(episode.podcast) {
                subscribeAction = UIAlertAction(title: "Subscribe to Podcast", style: .Default) { (action) in
                    User.sharedInstance.subscribe(episode.podcast)
                }
            } else {
                subscribeAction = UIAlertAction(title: "Unsubscribe to Podcast", style: .Default) { (action) in
                    User.sharedInstance.unsubscribe(episode.podcast)
                }
            }
            alertController.addAction(subscribeAction)
        }
        
        let tagAction = UIAlertAction(title: "Tag with Location", style: .Default) { (action) in
            self.performSegueWithIdentifier("addTagSegue", sender: self)
        }
        alertController.addAction(tagAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true){}
    }
    
    @IBAction func progressBarScrubbed(sender: UISlider) {
        // TODO : Implement
    }
    
}
