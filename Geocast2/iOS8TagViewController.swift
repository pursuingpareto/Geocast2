//
//  iOS8TagViewController.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/9/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class iOS8TagViewController: UIViewController {
    
    var geotag: Geotag!
    @IBOutlet weak var calloutView: CalloutView!
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var navItem: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        calloutView.setup(withGeotag: geotag)
        calloutView.playButton.addTarget(self, action: "playButtonPressed:", forControlEvents: .TouchUpInside)
        navItem.title = "Tag for \(geotag.episode.podcast.title)"
    }
    
    func playButtonPressed(sender: UIButton!) {
        print("Play button pressed")
        print("sender superview is \(sender.superview)")
        let episode = geotag.episode
        let userData = User.sharedInstance.getUserData(forEpisode: episode)
        PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userData, completion: {
            item in
        })
        
        let presentingVC = presentingViewController as! MainTabController
        presentingVC.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
        self.dismissViewControllerAnimated(true, completion: {})
        
    }
    @IBAction func backToMap(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
}
