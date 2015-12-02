//
//  Podcast.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

class Podcast: NSObject {
    let title: String
    let collectionId: Int
    let feedUrl: NSURL
    
    var thumbnailImageURL: NSURL? = nil
    var largeImageURL: NSURL? = nil
    var episodeCount: Int? = nil
    var lastUpdated: NSDate? = nil
    var summary: String? = nil
    var author: String? = nil
    
    init(title: String, collectionId: Int, feedUrl: NSURL) {
        self.title = title
        self.collectionId = collectionId
        self.feedUrl = feedUrl
    }
    
    
    class func podcastsWithJSON(allResults: NSArray) -> [Podcast] {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-ddThh:mm:ssZ"
        var podcasts = [Podcast]()
        if allResults.count>0 {
            for podcastInfo in allResults {
                
                if let kind = podcastInfo["kind"] as? String {
                    
                    if kind == "podcast" {
                        var name = podcastInfo["trackName"] as? String
                        if name == nil {
                            name = podcastInfo["collectionName"] as? String
                        }
                        if name == nil {
                            print("no name for podcast, continuing...")
                            continue
                        }
                        
                        guard let collectionId = podcastInfo["collectionId"] as? Int else {
                            print("no collection id, continuing...")
                            continue
                        }
                        
                        guard let feedUrlString = podcastInfo["feedUrl"] as? String else {
                            print("no feed URL string, continuing...")
                            continue
                        }
                        
                        guard let feedUrl: NSURL = NSURL(string: feedUrlString) else {
                            print("no feedURL, continuing...")
                            continue
                        }
                        
                        let podcast: Podcast = Podcast(title: name!, collectionId: collectionId, feedUrl: feedUrl)
                        
                        if let releaseDateString = podcastInfo["releaseDate"] as? String {
                            if let releaseDate = dateFormatter.dateFromString(releaseDateString) {
                                podcast.lastUpdated = releaseDate
                            }
                        }
                        
                        if let thumbnailURLString = podcastInfo["artworkUrl100"] as? String {
                            podcast.thumbnailImageURL = NSURL(string: thumbnailURLString)
                        }
                        
                        if let imageURLString = podcastInfo["artworkUrl600"] as? String {
                            podcast.largeImageURL = NSURL(string: imageURLString)
                        }
                        
                        if let episodeCount = podcastInfo["trackCount"] as? Int {
                            podcast.episodeCount = episodeCount
                        }
                        
                        podcasts.append(podcast)
                    }
                }
            }
        }
        
        return podcasts
    }
}
