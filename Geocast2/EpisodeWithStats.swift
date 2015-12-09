//
//  EpisodeWithStats.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import CoreData
import CoreMedia

@objc
class EpisodeWithStats: NSManagedObject {
    class func fromUserEpisodeData(data: UserEpisodeData) -> EpisodeWithStats {
        let ep = data.episode
        let ews = EpisodeWithStats()
        ews.mp3Url = ep.mp3URL.absoluteString
        ews.title = ep.title
        ews.totalSeconds = ep.duration
        ews.summary = ep.summary
        ews.subtitle = ep.subtitle
        ews.pubDate = ep.pubDate
        ews.itunesSummary = ep.iTunesSummary
        
        ews.lastPlayedAt = data.lastPlayedAt
        ews.lastPlayedTimestamp = data.lastPlayedTimestamp.seconds
        ews.fractionListenedTo  = data.fractionListenedTo
        if User.sharedInstance.isSubscribedTo(ep.podcast) {
            if let subscription = User.sharedInstance.getSubscription(forPodcast: ep.podcast) {
                ews.podcast = SubscribedPodcast.fromPodcastSubscription(podcastSubscription: subscription)
            } else {
                ews.podcast = nil
            }
        } else {
            ews.podcast = nil
        }
        return ews
    }
    
    func toUserEpisodeData() -> UserEpisodeData {
        let subscribedPC = self.podcast as! SubscribedPodcast
        let podcast = Podcast(title: subscribedPC.title, collectionId: Int(subscribedPC.collectionId), feedUrl: NSURL(string: subscribedPC.feedUrl)!)
        
        if let thumbURL = subscribedPC.thumbnailImageUrl {
            podcast.thumbnailImageURL = NSURL(string: thumbURL)
        }
        if let largeURL = subscribedPC.largeImageUrl {
            podcast.largeImageURL = NSURL(string: largeURL)
        }
        
        if let count = subscribedPC.episodeCount {
            podcast.episodeCount = Int(count)
        }
        if let lastUpdate = subscribedPC.lastUpdated {
            podcast.lastUpdated = lastUpdate
        }
        if let sum = subscribedPC.summary {
            podcast.summary = sum
        }
        if let auth = subscribedPC.author {
            podcast.author = auth
        }
        let ep = Episode(podcast: podcast, mp3URL: NSURL(string: mp3Url)!, title: title)
        let UED = UserEpisodeData(episode: ep)
        UED.lastPlayedAt = lastPlayedAt
        UED.fractionListenedTo = Float(fractionListenedTo)
        UED.lastPlayedTimestamp = CMTime(seconds: Double(lastPlayedTimestamp), preferredTimescale: 1)
        return UED
    }

}
