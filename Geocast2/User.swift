//
//  User.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

enum PodcastOrderingOption: Int {
    case SubscriptionDateDescending = 0
    case SubscriptionDateAscending = 1
    case Custom = 2
}

class User : NSObject {
    
    var podcastOrderingOption: PodcastOrderingOption = PodcastOrderingOption.SubscriptionDateDescending
    
    static let sharedInstance = User()
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerUpdated", name: playTimerUpdateNotificationKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
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
    
    func playerUpdated() {
        let player = PodcastPlayer.sharedInstance
        guard let ep = player.getCurrentEpisode() else {
            print("couldn't get current episode")
            return
        }
        if let sub = subscriptions[ep.podcast.collectionId] {
            if let data = sub?.episodeData[ep.mp3URL] {
                data?.lastPlayedAt = NSDate()
                if let timestamp = player.currentPlayTime {
                    data?.lastPlayedTimestamp = timestamp
                }
                guard let duration = player.duration else {
                    print("COULDN'T GET DURATION!")
                    return
                }
                guard let fraction = data?.fractionListenedTo else {
                    print("NO FRACTION!")
                    return
                }
                let secondsSoFar = fraction * Float(duration.seconds)
                let newSeconds = secondsSoFar + Float(player.timerUpdateIncrement)
                data?.fractionListenedTo = newSeconds / Float(duration.seconds)
            } else {
                print("No data for subscription!")
                let UED = UserEpisodeData(episode: ep)
                sub?.episodeData[ep.mp3URL] = UED
            }
        } else {
            print("did NOT get subscription")
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
    
    func getSubscriptions() -> [PodcastSubscription] {
        var subs: [PodcastSubscription] = []
        for sub in subscriptions.values {
            if sub != nil {
                subs.append(sub!)
            }
        }
        
        let order = self.podcastOrderingOption
        
        switch order {
        case PodcastOrderingOption.SubscriptionDateDescending:
            return subs.sort({$0.subscriptionDate.compare($1.subscriptionDate) == NSComparisonResult.OrderedDescending})
        case PodcastOrderingOption.SubscriptionDateAscending:
            return subs.sort({$0.subscriptionDate.compare($1.subscriptionDate) == NSComparisonResult.OrderedAscending})
        case PodcastOrderingOption.Custom:
            return subs
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
    
    func updateSubscriptionsWithNewPodcasts(podcasts: [Podcast]) {
        for newPC in podcasts {
            if self.isSubscribedTo(newPC) {
                let sub = getSubscription(forPodcast: newPC)!
                let oldPC = sub.podcast
                if oldPC.lastUpdated == nil {
                    oldPC.lastUpdated = newPC.lastUpdated
                } else if newPC.lastUpdated != nil {
                    if oldPC.lastUpdated!.compare(newPC.lastUpdated!) == NSComparisonResult.OrderedAscending {
                        oldPC.lastUpdated = newPC.lastUpdated
                    }
                }
                if oldPC.episodeCount == nil {
                    oldPC.episodeCount = newPC.episodeCount
                } else if newPC.episodeCount != nil {
                    if newPC.episodeCount > oldPC.episodeCount {
                        oldPC.episodeCount = newPC.episodeCount
                    }
                }
            }
        }
    }
    
    func updateSubscriptionData(forPodcast podcast: Podcast, withEpisodes episodes: [Episode]) {
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
    }
    
    func wipeSubscriptionsAndUpdate(withSubscriptions subs: [Int:PodcastSubscription]) {
        print("about to Wipe subscriptions and update...")
        self.subscriptions.removeAll()
        for (collID, podcastSub) in subs {
            print("...adding \(podcastSub.podcast.title) to dict with id \(collID)")
            self.subscriptions[collID] = podcastSub
        }
        print("user subscriptions has length \(subscriptions.count)")
        
    }
}