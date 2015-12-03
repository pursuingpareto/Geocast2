//
//  SubscriptionsController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UITableViewController {
    
    private let subscriptionCellIdentifier = "subscriptionCell"
    private let noSubscriptionsCellIdentifier = "noSubscriptionsCell"
    
    private let podcastSearchSegueIdentifier = "podcastSearchSegue"
    private let episodesSegueIdentifier = "episodesSegue"
    
    
    private var subscriptions : [PodcastSubscription] = [PodcastSubscription]()
    
    // TODO : Pull this out into something more global
//    private var imageCache = [String : UIImage]()
    private var customRefreshControl = UIRefreshControl()
    private var iTunesAPI : ITunesAPIController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO - listen for subscription changes
        setupNavBar()
        setupRefreshControl()
        iTunesAPI = ITunesAPIController(delegate: self)
        subscriptions = User.sharedInstance.getSubscriptions()
        lookupSubscriptionsFromITunes()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subscriptions = User.sharedInstance.getSubscriptions()
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case episodesSegueIdentifier:
                // TODO : Implement
                print("preparing for episodesSegue")
            case podcastSearchSegueIdentifier:
                // TODO : Implement
                print("preparing for podcactSearchSegue")
            default:
                break
            }
        }
        super.prepareForSegue(segue, sender: sender)
        
    }
    
    private func lookupSubscriptionsFromITunes() {
        if subscriptions.count > 0 {
            var collectionIds: [Int] = []
            for sub in subscriptions {
                collectionIds.append(sub.podcast.collectionId)
            }
            iTunesAPI.lookupPodcasts(collectionIds)
        }
    }
    
    private func setupNavBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addPodcast")
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.leftBarButtonItem = editButtonItem()
    }
    
    private func setupRefreshControl() {
        customRefreshControl.tintColor = UIColor.whiteColor()
        customRefreshControl.backgroundColor = UIColor.whiteColor()
        customRefreshControl.addTarget(self, action: "refreshPodcasts", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(customRefreshControl)
    }
    
    func refreshPodcasts() {
        // TODO : Implement
    }
    
    func addPodcast() {
        print("about to segue")
        performSegueWithIdentifier(podcastSearchSegueIdentifier, sender: self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (subscriptions.count == 0) ? 1 : subscriptions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var finalCell: UITableViewCell?
        
        if subscriptions.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(noSubscriptionsCellIdentifier) as! NoPodcastsCell
            finalCell = cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(subscriptionCellIdentifier)! as! PodcastCell
            let subscription = subscriptions[indexPath.row]
            let podcast = subscription.podcast
            cell.textLabel?.text = podcast.title
//            cell.titleLabel.text = podcast.title
//            var df = NSDateFormatter()
//            df.dateFormat = "yyyy-MM-dd"
//            let lastDate = df.dateFromString(podcast.lastUpdated)
//            if let lastDate = lastDate {
//                cell.detailLabel.text = "\(podcast.episodeCount!) Episodes, last \(lastDate.shortTimeAgoSinceNow())"
//            }
//            assignImage(toCellAtIndexPath: indexPath, withUrl: podcast.thumbnailImageURL)
//            cell!.detailTextLabel?.text = podcast["description"]
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            finalCell = cell
        }
        
        return finalCell!
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unsubscribe"
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let pc = subscriptions[indexPath.row].podcast
            User.sharedInstance.unsubscribe(pc)
//            userSubscriptionsUpdated()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return subscriptions.count > 0
    }
}

extension SubscriptionsViewController: ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast]) {
        print("got podcasts")
        // TODO - implement
    }
}
