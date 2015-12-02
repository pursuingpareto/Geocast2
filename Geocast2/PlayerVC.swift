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
    
    @IBOutlet private weak var playedTime: UILabel!
    @IBOutlet private weak var remainingTime: UILabel!
    @IBOutlet private weak var progressBar: UISlider!
    @IBOutlet private weak var trackTitle: UILabel!
    @IBOutlet private weak var podcastTitle: UILabel!
    @IBOutlet private weak var playButton: UIBarButtonItem!
    
    private var episode: Episode? = nil
    private var player = PodcastPlayer.sharedInstance
    private var fastForwardAmount = CMTimeMake(15, 1)
    private var rewindAmount = CMTimeMake(15, 1)
    
    private let addTagSegueIdentifier = "addTagSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        self.tabBarController?.tabBar.hidden = true
        let playerEpisode = player.getCurrentEpisode()
        if playerEpisode == nil {
            prepareNoDataView()
        } else {
            episode = playerEpisode
            prepareNormalView(withEpisode: episode!)
        }
        
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
        // TODO : Implement
    }
    
    private func prepareNormalView(withEpisode ep: Episode) {
        trackTitle.text = ep.title
        podcastTitle.text = ep.podcast.title
        // TODO : finish this
    }
    
    @IBAction private func playPausePressed(sender: AnyObject) {
        player.isPlaying ? player.pause() : player.play()
        // TODO : swap out buttons
    }
    
    @IBAction private func fastForwardPressed(sender: AnyObject) {
        player.fastForwardBy(fastForwardAmount)
    }
    
    @IBAction private func rewindPressed(sender: AnyObject) {
        player.rewindBy(rewindAmount)
    }
    
    @IBAction func hideButtonPressed(sender: AnyObject) {
        // TODO : Implement
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        // TODO : Implement
    }
    
    @IBAction func progressBarScrubbed(sender: UISlider) {
        // TODO : Implement
    }
    
}
