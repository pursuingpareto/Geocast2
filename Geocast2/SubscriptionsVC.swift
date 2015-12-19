//
//  SubscriptionsController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import DateTools
import Kingfisher

class SubscriptionsViewController: UITableViewController {
    
    private let subscriptionCellIdentifier = "subscriptionCell"
    private let noSubscriptionsCellIdentifier = "noSubscriptionsCell"
    
    private let podcastSearchSegueIdentifier = "podcastSearchSegue"
    private let episodesSegueIdentifier = "episodesSegue"
    
    private var subscriptions : [PodcastSubscription] = [PodcastSubscription]()
    
    private var customRefreshControl = UIRefreshControl()
    private var iTunesAPI : ITunesAPIController!
    
    private var secondsSinceLastUpdateRequiredToTriggerUpdate: Int = 1 * 60 * 60
    
    private var successfulUpdates = 0
    private var failingUpdates = 0
//    private var totalUpdates: Int = {
//        return self.subscriptions.count
//    }
    private var refreshLabel = UILabel()
    private var lastRefreshDate:NSDate? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO - listen for subscription changes
        setupNavBar()
        setupRefreshControl()
        iTunesAPI = ITunesAPIController(delegate: self)
//        subscriptions = User.sharedInstance.getSubscriptions()
//        lookupSubscriptionsFromITunes()
//        customRefreshControl.beginRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subscriptions = User.sharedInstance.getSubscriptions()
        
        if let lastUpdate = lastRefreshDate {
            print("programattically refreshing")
            let timeSinceLastUpdate = NSDate().timeIntervalSinceDate(lastUpdate)
            let seconds = Int(timeSinceLastUpdate)
            if seconds > secondsSinceLastUpdateRequiredToTriggerUpdate {
                customRefreshControl.beginRefreshing()
                tableView.setContentOffset(CGPoint(x: 0, y: -self.customRefreshControl.frame.size.height) , animated: true)
                
                refreshPodcasts()
            }
        } else {
            print("programattically refreshing")
            customRefreshControl.beginRefreshing()
            tableView.setContentOffset(CGPoint(x: 0, y: -self.customRefreshControl.frame.size.height) , animated: true)
            
            refreshPodcasts()
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    private func updateAllSubscriptionsInBackground() {
        print("updating all subscriptions in background")
        successfulUpdates = 0
        failingUpdates = 0
        for subscription in subscriptions {
            let podcast = subscription.podcast
            FeedParser.parsePodcast(podcast, withFeedParserDelegate: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("preparing for segue \(segue.identifier)")
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case episodesSegueIdentifier:
                // TODO : Implement
                let destinationVC = segue.destinationViewController as! EpisodesController
                let podcast = subscriptions[tableView.indexPathForSelectedRow!.row].podcast
//                dispatch_async(dispatch_get_main_queue(), {
                    print("about to assign episodesVC to podcast \(podcast.title)")
                    destinationVC.podcast = podcast
                    print("assigned episodes vc to podcast \(destinationVC.podcast)")
//                })
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
//        customRefreshControl.tintColor = UIColor.whiteColor()
//        customRefreshControl.backgroundColor = UIColor.whiteColor()
        customRefreshControl.addTarget(self, action: "refreshPodcasts", forControlEvents: UIControlEvents.ValueChanged)
        customRefreshControl.bounds = CGRect(x: 0, y: 0, width: customRefreshControl.bounds.width, height: 1.4 * customRefreshControl.bounds.height)
        
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        
        customRefreshControl.addSubview(refreshLabel)
        tableView.addSubview(customRefreshControl)
        
        let leftConstraint = NSLayoutConstraint(item: refreshLabel, attribute: .Leading, relatedBy: .Equal, toItem: customRefreshControl, attribute: .Leading, multiplier: 1, constant: 0)
        view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: refreshLabel, attribute: .Trailing, relatedBy: .Equal, toItem: customRefreshControl, attribute: .Trailing, multiplier: 1, constant: 0)
        view.addConstraint(rightConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: refreshLabel, attribute: .Bottom, relatedBy: .Equal, toItem: customRefreshControl, attribute: .Bottom, multiplier: 1, constant: 4)
        view.addConstraint(bottomConstraint)
        
//        let topConstraint = NSLayoutConstraint(item: refreshLabel, attribute: .Top, relatedBy: .Equal, toItem: customRefreshControl, attribute: .CenterY , multiplier: 1, constant: 0)
//        view.addConstraint(topConstraint)
        
        let heightConstraint = NSLayoutConstraint(item: refreshLabel, attribute: .Height, relatedBy: .Equal, toItem: nil , attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        view.addConstraint(heightConstraint)
        
        refreshLabel.textAlignment = .Center
        refreshLabel.textColor = UIColor.lightGrayColor()
        refreshLabel.font = UIFont(name: refreshLabel.font.fontName, size : 14)
    }
    
    private func stringForRefreshControl() -> String {
        if let lastDate = lastRefreshDate {
            return "\(successfulUpdates) of \(self.subscriptions.count) podcasts updated, last \(lastDate.shortTimeAgoSinceNow())"
        } else {
            return "\(successfulUpdates) of \(self.subscriptions.count) podcasts updated"
        }
    }
    
    func refreshPodcasts() {
        if subscriptions.count > 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshLabel.text = self.stringForRefreshControl()
                //            self.refreshLabel.sizeToFit()
            })
            
            updateAllSubscriptionsInBackground()
        } else {
            customRefreshControl.endRefreshing()
        }
        
    }
    
    func addPodcast() {
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
//            cell.textLabel?.text = podcast.title
            cell.titleLabel.text = podcast.title

            if let lastDate = podcast.lastUpdated {

                cell.detailLabel.text = "\(podcast.episodeCount!) Episodes, last \(lastDate.shortTimeAgoSinceNow()) ago"
            } else {
                print("NO UPDATE TIME!")
            }
            if let url = podcast.thumbnailImageURL {
                cell.podcastImageView.kf_showIndicatorWhenLoading = true
                cell.podcastImageView.kf_setImageWithURL(url)
            } else {
                print("No thumbnailImageURL for \(podcast.title)")
            }
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            finalCell = cell
        }
        
        return finalCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(episodesSegueIdentifier, sender: self)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unsubscribe"
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let pc = subscriptions[indexPath.row].podcast
            User.sharedInstance.unsubscribe(pc)
            subscriptions = User.sharedInstance.getSubscriptions()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
//            dispatch_async(dispatch_get_main_queue(), {
//                self.tableView.reloadData()
//            })
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return subscriptions.count > 0
    }
    
}

extension SubscriptionsViewController: ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast]) {
        print("got podcasts")
        User.sharedInstance.updateSubscriptionsWithNewPodcasts(podcasts)
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
        // TODO - implement
    }
}

extension SubscriptionsViewController: FeedParserDelegate {
    func didParseFeedIntoEpisodes(episodes: [Episode]) {
        guard let podcast = episodes.first?.podcast else {
            return
        }
        successfulUpdates += 1
        print("successful updates is now \(successfulUpdates)")
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshLabel.text = self.stringForRefreshControl()
        })
        
        User.sharedInstance.updateSubscriptionData(forPodcast: podcast, withEpisodes: episodes)
//        User.sharedInstance.updateSubscriptionsWithNewPodcasts([podcast])
        // TODO : reassign subscriptions and reload data!
        
        if (successfulUpdates + failingUpdates) == self.subscriptions.count {
            customRefreshControl.endRefreshing()
            successfulUpdates = 0
            failingUpdates = 0
            subscriptions = User.sharedInstance.getSubscriptions()
            lastRefreshDate = nil
            refreshLabel.text = stringForRefreshControl()
            lastRefreshDate = NSDate()
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
        
    }
}
