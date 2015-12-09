//
//  SearchController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class PodcastSearchController: UITableViewController {
    
    private let subscriptionCellIdentifier = "subscriptionCell"
    
    private let episodesSegueIdentifier = "episodesSegue"
    
    private var podcastsFound = [Podcast]()
    private var searchController: UISearchController!
    private var iTunesAPI: ITunesAPIController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        iTunesAPI = ITunesAPIController(delegate: self)
        setupSearchController()
        navigationItem.title = "Search"
        tableView.reloadData()
//        tableView.delegate = self
//        tableView.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchController.active = true
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let episodesController = segue.destinationViewController as? EpisodesController {
            let podcast = podcastsFound[tableView.indexPathForSelectedRow!.row]
            episodesController.setPodcast(podcast)
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    private func setupSearchController() {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.sizeToFit()
        controller.searchBar.placeholder = "Search for Podcasts"
        controller.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = controller.searchBar
        searchController = controller
        searchController.delegate = self
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(subscriptionCellIdentifier)! as! PodcastCell
        let podcast = podcastsFound[indexPath.row]
        //            cell.textLabel?.text = podcast.title
        cell.titleLabel.text = podcast.title
        
        if let lastDate = podcast.lastUpdated {

            cell.detailLabel.text = "\(podcast.episodeCount!) Episodes, last \(lastDate.shortTimeAgoSinceNow())"
        } else {
            print("NO UPDATE TIME for \(podcast.title)!")
        }
        
        PersistenceManager.sharedInstance.attemptToGetImageFromCache(withURL: podcast.thumbnailImageURL, completion: { image -> Void in
            if let image = image {
                dispatch_async(dispatch_get_main_queue(), {
                    let updateCell = tableView.cellForRowAtIndexPath(indexPath)
                    if let updateCell = updateCell as? PodcastCell {
                        updateCell.podcastImageView.image = image
                    }
                })
            }
        })
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcastsFound.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(episodesSegueIdentifier, sender: self)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
}

extension PodcastSearchController: ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast]) {
        self.podcastsFound = podcasts
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
}

extension PodcastSearchController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
//        podcastsFound.removeAll(keepCapacity: false)
        iTunesAPI.searchPodcasts(searchController.searchBar.text!)
    }
}

extension PodcastSearchController: UISearchControllerDelegate {
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
}
