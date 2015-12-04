//
//  User.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

enum PodcastOrderingOption {
    case SubscriptionDateDescending
    case SubscriptionDateAscending
}

class User : NSObject {
    static let sharedInstance = User()
    
    // the key is the podcast collection id
    private var subscriptions = [Int : PodcastSubscription?]()
    
    func subscribe(podcast: Podcast) -> Bool {
        if isSubscribedTo(podcast) {
            return false
        } else {
            let subscription = PodcastSubscription(podcast: podcast)
            subscriptions[podcast.collectionId] = subscription
            return true
        }
    }
    
    func unsubscribe(podcast: Podcast) -> Bool {
        if isSubscribedTo(podcast) {
            subscriptions.removeValueForKey(podcast.collectionId)
            return true
        } else {
           return false
        }
    }
    
    func getSubscriptions(orderedBy order: PodcastOrderingOption = .SubscriptionDateDescending) -> [PodcastSubscription] {
        var subs: [PodcastSubscription] = []
        for sub in subscriptions.values {
            if sub != nil {
                subs.append(sub!)
            }
        }
        switch order {
        case PodcastOrderingOption.SubscriptionDateDescending:
            return subs.sort({$0.subscriptionDate.compare($1.subscriptionDate) == NSComparisonResult.OrderedDescending})
        case PodcastOrderingOption.SubscriptionDateAscending:
            return subs.sort({$0.subscriptionDate.compare($1.subscriptionDate) == NSComparisonResult.OrderedAscending})
        }
    }
    
    func getSubscription(forPodcast podcast: Podcast) -> PodcastSubscription? {
        if let subscription = subscriptions[podcast.collectionId] {
            return subscription
        } else {
            return nil
        }
    }
    
    func isSubscribedTo(podcast: Podcast) -> Bool {
        if let sub = subscriptions[podcast.collectionId] {
            if sub != nil {
                return true
            }
        }
        return false
    }
    
    func getUserData(forEpisode episode: Episode) -> UserEpisodeData? {
        guard let subscription = subscriptions[episode.podcast.collectionId] else {
            return nil
        }
        guard let data = subscription?.episodeData[episode.mp3URL] else {
            return nil
        }
        return data
    }
    
    func wipeSubscriptionsAndUpdate(withSubscriptions subs: [Int:PodcastSubscription]) {
        self.subscriptions.removeAll()
        for (collID, podcastSub) in subs {
            self.subscriptions[collID] = podcastSub
        }
    }
}