//
//  SubscriptionsController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UITableViewController {
    
    let subscriptionCellIdentifier = "subscriptionCell"
    let podcastSearchSegueIdentifier = "podcastSearchSegue"
    let episodesSegueIdentifier = "episodesSegue"
    var subscriptions : [PodcastSubscription] = [PodcastSubscription]()
    var imageCache = [String : UIImage]()
    var customRefreshControl = UIRefreshControl()
    var iTunesAPI : ITunesAPIController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iTunesAPI = ITunesAPIController(delegate: self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscriptions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(subscriptionCellIdentifier, forIndexPath: indexPath)
        let subscription = subscriptions[indexPath.row]
        cell.textLabel?.text = subscription.podcast.title
        return cell
    }
}

extension SubscriptionsViewController: ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast]) {
        print("got podcasts")
        // TODO - implement
    }
}
