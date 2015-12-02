//
//  SearchController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class PodcastSearchController: UITableViewController {
    
    let searchResultIdentifier = "searchResultCell"
    
    private var podcastsFound = [Podcast]()
    private let searchController = UISearchController()
    var iTunesAPI: ITunesAPIController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iTunesAPI = ITunesAPIController(delegate: self)
        setupSearchController()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search for Podcasts"
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let podcast: Podcast = podcastsFound[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(searchResultIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = podcast.title
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcastsFound.count
    }
}

extension PodcastSearchController: ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast]) {
        self.podcastsFound = podcasts
        tableView.reloadData()
    }
}

extension PodcastSearchController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        iTunesAPI.searchPodcasts(searchController.searchBar.text!)
    }
}

extension PodcastSearchController: UISearchControllerDelegate {
    func didPresentSearchController(searchController: UISearchController) {
        print("Did present search controller")
        searchController.searchBar.becomeFirstResponder()
    }
}
