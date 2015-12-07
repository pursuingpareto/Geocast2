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

class EpisodesController : UITableViewController {
    
    private let playerSegueIdentifier = "playerSegue"
    private let summaryCellIdentifier = "podcastSummaryCell"
    private let episodeCellIdentifier = "episodeCell"
    
    private var podcast: Podcast!
    private var episodes = [Episode]()
    
    @IBOutlet weak var subscribeButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = podcast.title
        let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(17)]
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(attrs, forState: .Normal)
        FeedParser.parsePodcast(podcast, withFeedParserDelegate: self)
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setPodcast(podcast: Podcast) {
        self.podcast = podcast
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    private func episodeForIndexPath(indexPath: NSIndexPath) -> Episode? {
        return (indexPath.row == 0) ? nil : episodes[indexPath.row - 1]
    }
    
    private func updateSubscriptionDataWithCurrentEpisodes() {
        podcast.episodeCount = episodes.count
        if podcast.lastUpdated == nil {
            podcast.lastUpdated = episodes.first?.pubDate
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
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
        
    }
    
    func subscribeButtonClicked(sender: AnyObject?) {
        User.sharedInstance.subscribe(podcast)
        if let button = sender as? UIButton {
            UIView.animateWithDuration(0.1, animations: {
                button.alpha = 0.0
                }, completion: { _ in
                    button.hidden = true
                    self.updateSubscriptionDataWithCurrentEpisodes()
            })
        }
    }
    
    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        User.sharedInstance.subscribe(podcast)
        navigationItem.setRightBarButtonItem(nil , animated: true)

//        UIView.animateWithDuration(0.1, animations: {
//            self.subscribeButton. = 0.0
//            }, completion: { _ in
//                button.hidden = true
//                self.updateSubscriptionDataWithCurrentEpisodes()
//        })

    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(summaryCellIdentifier, forIndexPath: indexPath) as! PodcastSummaryCell
            cell.podcastTitle.text = podcast.title

            cell.podcastSummary.text = podcast.summary
            
            cell.subscribeButton.hidden = true

//            if User.sharedInstance.isSubscribedTo(podcast) {
//                cell.subscribeButton.hidden = true
//            } else {
//                cell.subscribeButton.addTarget(self, action: "subscribeButtonClicked:", forControlEvents: .TouchUpInside)
//            }
            PersistenceManager.sharedInstance.attemptToGetImageFromCache(withURL: podcast.thumbnailImageURL, completion: { image -> Void in
                if let image = image {
                    dispatch_async(dispatch_get_main_queue(), {
                        let updateCell = tableView.cellForRowAtIndexPath(indexPath)
                        if let updateCell = updateCell as? PodcastSummaryCell {
                            updateCell.podcastImageView.image = image
                        }
                    })
                }
            })


            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(episodeCellIdentifier, forIndexPath: indexPath) as! EpisodeCell
            let episode = episodeForIndexPath(indexPath)!
//            cell.textLabel?.text = episode.title
            
            cell.episodeTitle.text = episode.title
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let episode = episodeForIndexPath(indexPath) {
            let userEpisodeData: UserEpisodeData? = User.sharedInstance.getUserData(forEpisode: episode)
            PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userEpisodeData, completion: {(item) in
            })
            tabBarController?.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return (indexPath.row == 0) ? false : true
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return (indexPath.row == 0) ? 150 : 90
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
        tableView.reloadData()
    }
    
    func didParseFeedIntoEpisodes(episodes: [Episode]) {
        self.episodes = episodes
        updateSubscriptionDataWithCurrentEpisodes()
    }
}