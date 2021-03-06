//
//  EpisodesVC.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/1/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import DateTools
import CoreMedia
import Kingfisher

class EpisodesController : UITableViewController {
    
    private let playerSegueIdentifier = "playerSegue"
    private let summaryCellIdentifier = "podcastSummaryCell"
    private let episodeCellIdentifier = "episodeCell"
    private let loadingCellIdentifier = "loadingCell"
    
    private var summaryCellExpanded: Bool = false
    var podcast: Podcast!
    
    private var episodes = [Episode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = podcast.title
        if User.sharedInstance.isSubscribedTo(podcast) {
            navigationItem.setRightBarButtonItem(nil, animated: false)
        } else {
            let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(17)]
            navigationItem.rightBarButtonItem?.setTitleTextAttributes(attrs, forState: .Normal)
        }
        if User.sharedInstance.isSubscribedTo(podcast) {
            let subscription = User.sharedInstance.getSubscription(forPodcast: podcast)
            var eps: [Episode] = []
            for ued in (subscription?.episodeData.values)! {
                if let newEp = ued?.episode {
                    let index = eps.insertionIndexOf(newEp, isOrderedBefore: {
                        ep1, ep2 -> Bool in
                        if let d1 = ep1.pubDate {
                            if let d2 = ep2.pubDate {
                                return (d1.compare(d2) == NSComparisonResult.OrderedDescending)
                            } else {
                                print("no pubDate for \(ep2.title)")
                            }
                        } else {
                            print("no pubDate for \(ep1.title)")
                        }
                        return true
                    })
                    eps.insert(newEp, atIndex: index)
                }
            }
            episodes = eps
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        } else {
//            tableView.hidden = true
        }
        
        // TODO : Check if this is really necessary
        FeedParser.parsePodcast(podcast, withFeedParserDelegate: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("preparing for segue to \(segue.destinationViewController)")
        if let vc = segue.destinationViewController as? PlayerViewController {
            print("setting shouldPlay to true")
            guard let indexPath = tableView.indexPathForSelectedRow else {
                return
            }
            guard let episode = episodeForIndexPath(indexPath) else {
                return
            }
            
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    private func switchToPlayer(withEpisode episode: Episode) {
        let vc = tabBarController!.viewControllers![MainTabController.TabIndex.playerIndex.rawValue] as! PlayerViewController
        vc.shouldPlay = true
        let userEpisodeData: UserEpisodeData? = User.sharedInstance.getUserData(forEpisode: episode)
        PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userEpisodeData, completion: {(item) in
        })
        tabBarController?.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
//    func setPodcast(podcast: Podcast) {
//        self.podcast = podcast
//    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    private func episodeForIndexPath(indexPath: NSIndexPath) -> Episode? {
        return (indexPath.row == 0) ? nil : episodes[indexPath.row - 1]
    }
    
    // TODO : delete this and switch to implementation in User.swift
    private func updateSubscriptionDataWithCurrentEpisodes() {
        podcast.episodeCount = episodes.count
        if podcast.lastUpdated == nil {
            podcast.lastUpdated = episodes.first?.pubDate
        } else if let mostRecentEpPubDate = episodes.first?.pubDate {
            if podcast.lastUpdated!.compare(mostRecentEpPubDate) == NSComparisonResult.OrderedAscending {
                podcast.lastUpdated = mostRecentEpPubDate
            }
        }
        let user = User.sharedInstance
        let subscription = user.getSubscription(forPodcast: podcast)
        for episode in episodes {
            if let userData = user.getUserData(forEpisode: episode) {
                continue
            } else {
                let newEpisodeData = UserEpisodeData(episode: episode)
                subscription?.episodeData[episode.mp3URL] = newEpisodeData
            }
        }
    }
    
    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        User.sharedInstance.subscribe(podcast)
        navigationItem.setRightBarButtonItem(nil , animated: true)
        updateSubscriptionDataWithCurrentEpisodes()
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if episodes.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(loadingCellIdentifier, forIndexPath: indexPath) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        } else  {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(summaryCellIdentifier, forIndexPath: indexPath) as! PodcastSummaryCell
                cell.podcastSummary.text = podcast.summary
                cell.podcastSummary.numberOfLines = summaryCellExpanded ? 0 : 4
                cell.podcastSummary.lineBreakMode = summaryCellExpanded ? NSLineBreakMode.ByWordWrapping : NSLineBreakMode.ByTruncatingTail
                if let url = podcast.thumbnailImageURL {
                    cell.podcastImageView.kf_showIndicatorWhenLoading = true
                    cell.podcastImageView.kf_setImageWithURL(url)
                } else {
                    print("no thumbnailImageURL available for \(podcast.title)")
                    // TODO : handle default images
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(episodeCellIdentifier, forIndexPath: indexPath) as! EpisodeCell
                let episode = episodeForIndexPath(indexPath)!
                cell.episodeTitle.text = episode.title
                cell.episodeTitle.sizeToFit()
                if let duration = episode.duration {
                    let cmDuration = CMTime(seconds: duration, preferredTimescale: 1)
                    cell.duration.text = cmDuration.asString()
                }
                cell.progressBar.setProgress(0.0, animated: false)
                if let subscription = User.sharedInstance.getSubscription(forPodcast: podcast) {
                    if let data = subscription.episodeData[episode.mp3URL] {
                        cell.progressBar.setProgress(data!.fractionListenedTo, animated: false)
                    }
                }
                
                if let date = episode.pubDate {
                    let formatter = NSDateFormatter()
                    formatter.dateStyle = .MediumStyle
                    cell.publicationDate.text = formatter.stringFromDate(date)
                }
                return cell
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            summaryCellExpanded = !summaryCellExpanded
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        if let episode = episodeForIndexPath(indexPath) {
            switchToPlayer(withEpisode: episode )
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return (indexPath.row == 0) ? false : true
        return true
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if episodes.count > 0 {
            return (indexPath.row == 0) ? UITableViewAutomaticDimension : 90
        } else {
//            tableView.layoutIfNeeded()
            return tabBarController!.tabBar.frame.origin.y - navigationController!.navigationBar.frame.origin.y
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
}

extension EpisodesController: FeedParserDelegate {
    
    func didParsePodcastSummaryData(data: [String : String]) {
        podcast.summary = data["description"]
        podcast.author = data["itunes:author"]
        if let lastUpdatedString = data["lastBuildDate"] {
            var df = NSDateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let lastDate = df.dateFromString(lastUpdatedString) {
                podcast.lastUpdated = lastDate
            }
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
        
    }
    
    func didParseFeedIntoEpisodes(episodes: [Episode]) {
        self.episodes = episodes
        updateSubscriptionDataWithCurrentEpisodes()
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? LoadingCell {
            cell.activityIndicator.stopAnimating()
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
}