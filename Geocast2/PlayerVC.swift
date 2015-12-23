//
//  PlayerVC.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/1/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher

class PlayerViewController: UIViewController {
    
    enum ReadinessState: Int {
        case NoData = 0
        case Loading = 1
        case Normal = 2
    }
    
    var shouldPlay: Bool = false
    
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
        if let mainTabVC = self.tabBarController as? MainTabController {
            self.tabBarController?.selectedIndex = mainTabVC.lastSelectedIndex
        }
        assignBackgroundImage()
        assignSummaryText()
    }
    
    private func assignBackgroundImage() {
        if let podcast = PodcastPlayer.sharedInstance.getCurrentEpisode()?.podcast {
            if let url = podcast.largeImageURL {
                imageView.kf_setImageWithURL(url)
            }
        } else {
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
                self.summaryTextView.text = self.removeHTMLFromString(summary)
            })
        } else if let summary = episode.iTunesSummary {
            dispatch_async(dispatch_get_main_queue(), {
                self.summaryTextView.text = self.removeHTMLFromString(summary)
            })
        }
    }
    
    private func removeHTMLFromString(string: String) -> String {
        var regex: NSRegularExpression? = nil
        do {
            regex = try NSRegularExpression(pattern: "<.*?>", options:  NSRegularExpressionOptions.CaseInsensitive)
        } catch {
            print("error forming regex \(error)")
        }
        let range = NSMakeRange(0, string.characters.count)
        let noHTMLString = regex?.stringByReplacingMatchesInString(string, options: [], range: range, withTemplate: "")
        if let str = noHTMLString {
            return str
        } else {
            return string
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Preparing for segue \(segue.identifier)")
        if segue.identifier == addTagSegueIdentifier {
            let navController = segue.destinationViewController as! UINavigationController
            let tagVC = navController.childViewControllers.last as! NewTagController
            if let episode = player.getCurrentEpisode() {
                tagVC.episode = episode
            } else {
                return
            }
        }
        if let tabVC = self.tabBarController as? MainTabController {
            print("changing lastSelected from \(tabVC.lastSelectedIndex) to \(MainTabController.TabIndex.playerIndex.rawValue)")
            tabVC.lastSelectedIndex = MainTabController.TabIndex.playerIndex.rawValue
        } else {
            print("NOT changing lastSelected to \(MainTabController.TabIndex.playerIndex.rawValue)")
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        super.remoteControlReceivedWithEvent(event)
        if event?.type == .RemoteControl {
            player.remoteControlReceivedWithEvent(event)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateToolbar", name: applicationBecameActiveNotificationKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func setupProgressBar() {
        let verticalBar = UIImage(named: "white_vertical_bar")
        let size = CGSizeApplyAffineTransform((verticalBar!.size), CGAffineTransformMakeScale(0.05, 0.03))
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
        pubDate.textColor = UIColor.whiteColor()
        
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
    }
    
    func playerItemStatusChanged() {
        if getCurrentReadinessState() == .Normal {
            if shouldPlay {
                player.play()
                shouldPlay = false
            }
        }
        updateEnabledStatesOfView()
    }
    
    private func updateEnabledStatesOfView() {
        let readinessState = getCurrentReadinessState()
        print("readinessState is \(readinessState)")
        switch readinessState {
        case .Normal:
            progressBar.userInteractionEnabled = true
            for btn in playbackToolbar.items! {
                btn.enabled = true
            }
        default:
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
        print("Scrubbed!")
        let progress = sender.value
        if let duration = PodcastPlayer.sharedInstance.duration {
            let seconds = Int64(progress * Float(duration.seconds))
            player.seekToTime(CMTimeMake(seconds, 1))
//            if player.isPlaying {
//                player.play()
//            } else {
//                player.pause()
//            }
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
//        self.tabBarController?.selectedIndex = MainTabController.TabIndex.podcastIndex.rawValue
        if let mainTabVC = self.tabBarController as? MainTabController {
            if mainTabVC.lastSelectedIndex != MainTabController.TabIndex.playerIndex.rawValue {
                self.tabBarController?.selectedIndex = mainTabVC.lastSelectedIndex
            } else {
                self.tabBarController?.selectedIndex = MainTabController.TabIndex.podcastIndex.rawValue
            }
            
        }
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
