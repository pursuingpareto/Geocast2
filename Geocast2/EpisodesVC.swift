//
//  EpisodesVC.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/1/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class EpisodesController : UITableViewController {
    
    private let playerSegueIdentifier = "playerSegue"
    private let summaryCellIdentifier = "podcastSummaryCell"
    private let episodeCellIdentifier = "episodeCell"
    
    private var podcast: Podcast!
    private var episodes = [Episode]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        FeedParser.parsePodcast(podcast, withFeedParserDelegate: self)
//        tableView.reloadData()
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
    
    func subscribeButtonClicked(sender: AnyObject?) {
        print("subscribing user to \(podcast.title)")
        User.sharedInstance.subscribe(podcast)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(summaryCellIdentifier, forIndexPath: indexPath) as! PodcastSummaryCell
            cell.podcastTitle.text = podcast.title
            print("podcast is \(podcast.title)")
            cell.podcastSummary.text = podcast.summary
            print("summary is \(podcast.summary)")
            if User.sharedInstance.isSubscribedTo(podcast) {
                cell.subscribeButton.hidden = true
            } else {
                cell.subscribeButton.addTarget(self, action: "subscribeButtonClicked:", forControlEvents: .TouchUpInside)
            }
            print("summary cell is \(cell)")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(episodeCellIdentifier, forIndexPath: indexPath) as! EpisodeCell
            let episode = episodeForIndexPath(indexPath)!
            cell.textLabel?.text = episode.title
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let episode = episodeForIndexPath(indexPath) {
            let userEpisodeData: UserEpisodeData? = User.sharedInstance.getUserData(forEpisode: episode)
            tabBarController?.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
            PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userEpisodeData, completion: {(item) in
            })
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
        tableView.reloadData()
    }
    
    func didParseFeedIntoEpisodes(episodes: [Episode]) {
        self.episodes = episodes
        tableView.reloadData()
    }
}