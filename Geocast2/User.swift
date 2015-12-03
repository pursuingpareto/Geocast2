//
//  User.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

class User : NSObject {
    static let sharedInstance = User()
    
    // the key is the podcast collection id
    private let subscriptions = [Int : PodcastSubscription?]()
    
    func subscribe(podcast: Podcast) -> Bool {
        return false
    }
    
    func unsubscribe(podcast: Podcast) -> Bool {
        return false
    }
    
    func getSubscriptions() -> [PodcastSubscription] {
        return []
    }
    
    func getUserData(forEpisode episode: Episode) -> UserEpisodeData? {
        guard let subscription = subscriptions[episode.podcast.collectionId] else {
            return nil
        }
        guard let data = subscription!.episodeData[episode.mp3URL] else {
            return nil
        }
        return data
    }
}