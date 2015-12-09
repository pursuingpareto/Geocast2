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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var summaryTextView: UITextView!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    private var player = PodcastPlayer.sharedInstance
    
    private let addTagSegueIdentifier = "addTagSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressBar()
        setupListeners()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareView(forReadinessState: getCurrentReadinessState())
        assignBackgroundImage()
        assignSummaryText()
    }
    
    private func assignBackgroundImage() {
        print("about to try getting podcast...")
        if let podcast = PodcastPlayer.sharedInstance.getCurrentEpisode()?.podcast {
            print(" got podcast")
            PersistenceManager.sharedInstance.attemptToGetImageFromCache(withURL: podcast.largeImageURL, completion: { image -> Void in
                print(" assigning image view to \(image)")
                guard let image = image else {
                    return
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageView.image = image
                })
            })
        } else {
            print("failed to get podcast")
            dispatch_async(dispatch_get_main_queue(), {
                self.imageView.image = nil
            })
        }
    }
    
    private func assignSummaryText() {
        guard let episode = PodcastPlayer.sharedInstance.getCurrentEpisode() else {
            return
        }
        if let summary = episode.summary {
            dispatch_async(dispatch_get_main_queue(), {
                self.summaryTextView.text = summary
            })
        } else if let summary = episode.iTunesSummary {
            dispatch_async(dispatch_get_main_queue(), {
                self.summaryTextView.text = summary
            })
        }
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
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        super.remoteControlReceivedWithEvent(event)
        if event?.type == .RemoteControl {
            player.remoteControlReceivedWithEvent(event)
        }
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
            print("no data")
            return .NoData
        } else if player.currentItemStatus != .ReadyToPlay {
            print("loading")
            return .Loading
        } else {
            print("normal")
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
        // hide stuff we don't want to see
        imageView.hidden = true
        progressBar.hidden = true
        remainingTime.hidden = true
        playedTime.hidden = true
        summaryTextView.hidden = true
        settingsButton.hidden = true
        playbackToolbar.hidden = true
        hideButton.hidden = true
        trackTitle.hidden = true
        podcastTitle.hidden = true
        
        pubDate.hidden = false
        pubDate.text = "Please select an episode to begin playing."
        
        tabBarController?.tabBar.hidden = false
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
        
        // put image in the middle
//        let upper = pubDate.frame.origin.y + pubDate.frame.height
//        let lower = playbackToolbar.frame.origin.y
//        
//        let middle = (upper + lower) / 2.0
//        
//        imageView.center.y = middle
//        summaryTextView.center.y = middle
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
        if let playTime = player.currentPlayTime {
            playedTime.text = playTime.asString()
            if let duration = player.duration {
                remainingTime.text = (duration - playTime).asString()
                let progress = playTime.seconds / duration.seconds
                progressBar.value = Float(progress)
            }
            
        }
    }
    
    @IBAction func scrubbedPlayer(sender: UISlider) {
        let progress = sender.value
        if let duration = PodcastPlayer.sharedInstance.duration {
            let seconds = Int64(progress * Float(duration.seconds))
            player.seekToTime(CMTimeMake(seconds, 1))
            if player.isPlaying {
                player.play()
            } else {
                player.pause()
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
        player.fastForwardBy(player.fastForwardAmount)
    }
    
    @IBAction private func rewindPressed(sender: AnyObject) {
        player.rewindBy(player.rewindAmount)
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
