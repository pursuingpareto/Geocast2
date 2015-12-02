//
//  EpisodesVC.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/1/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class EpisodesController : UITableViewController {
    
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(episodeCellIdentifier, forIndexPath: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.row]
        cell.textLabel?.text = episode.title
        return cell
    }
}

extension EpisodesController: FeedParserDelegate {
    
    func didParseFeedIntoEpisodes(episodes: [Episode]) {
        self.episodes = episodes
        tableView.reloadData()
    }
}