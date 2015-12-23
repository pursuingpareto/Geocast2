//
//  PersistenceManager.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher

class PersistenceManager: NSObject {
    
    static let sharedInstance = PersistenceManager()
    
    private let maxDiskCacheMB: UInt = 300
    private let maxCachePeriodDays: Double = 30
    
    override init() {
        super.init()
        KingfisherManager.sharedManager.cache.maxDiskCacheSize = maxDiskCacheMB * 1024 * 1024
        KingfisherManager.sharedManager.cache.maxCachePeriodInSecond = maxCachePeriodDays * 24 * 60 * 60
    }
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func fetchSubscriptionData() -> [SubscribedPodcast]? {
        let subscriptionRequest = NSFetchRequest(entityName: "SubscribedPodcast")
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(subscriptionRequest) as? [SubscribedPodcast]
            return fetchResults
        } catch {
            print("error")
            return nil
        }
    }
    
    func fetchEpisodeData() -> [EpisodeWithStats]? {
        let request = NSFetchRequest(entityName: "EpisodeWithStats")
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(request) as? [EpisodeWithStats]
            return fetchResults
        } catch {
            print("error")
            return nil
        }
    }
    
    func updateUserWithStoredData() {
        print("updating user with stored data...")
        if let subscribedPCs = fetchSubscriptionData() {
            var userSubs = [Int: PodcastSubscription]()
            for subscribedPC in subscribedPCs {
                let pcSub = subscribedPC.toPodcastSubscription()
                userSubs[pcSub.podcast.collectionId] = pcSub
            }
            if let epsWithStats = fetchEpisodeData() {
                for ep in epsWithStats {
                    let userEpisodeData = ep.toUserEpisodeData()
//                    let podcastSub = (ep.podcast as! SubscribedPodcast).toPodcastSubscription()
                    guard let podcastSub: PodcastSubscription = userSubs[userEpisodeData.episode.podcast.collectionId] else {
                        print("Couldn't find the podcast sub asssociated with user episode data \(userEpisodeData)")
                        continue
                    }
//                    let collectionId = podcastSub.podcast.collectionId
//                    if let sub: PodcastSubscription = userSubs[collectionId] {
//                        // this podcast has already been added to subscriptions
                        podcastSub.episodeData[userEpisodeData.episode.mp3URL] = userEpisodeData
//                    }
                }
                print("about to wipe and update!!")
                User.sharedInstance.wipeSubscriptionsAndUpdate(withSubscriptions: userSubs)
            }
        }
    }
    
    func saveAllUserData() {
        var fetchRequest = NSFetchRequest(entityName: "SubscribedPodcast")
        if #available(iOS 9.0, *) {
            var deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try managedObjectContext.persistentStoreCoordinator?.executeRequest(deleteRequest, withContext: managedObjectContext)
            } catch let error as NSError {
                print("error saving user data: \(error)")
            }
        } else {
            do {
                let objects = try managedObjectContext.executeFetchRequest(fetchRequest) as! [SubscribedPodcast]
                for obj in objects {
                    managedObjectContext.deleteObject(obj)
                }
            } catch {
                print("iOS8 error \(error)")
            }
        }
        
        
        
        fetchRequest = NSFetchRequest(entityName: "EpisodeWithStats")
        if #available(iOS 9.0, *) {
            var deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try managedObjectContext.persistentStoreCoordinator?.executeRequest(deleteRequest, withContext: managedObjectContext)
            } catch let error as NSError {
                print("error saving user data: \(error)")
            }
        } else {
            do {
                let objects = try managedObjectContext.executeFetchRequest(fetchRequest) as! [EpisodeWithStats]
                for obj in objects {
                    managedObjectContext.deleteObject(obj)
                }
            } catch {
                print("iOS8 error \(error)")
            }
        }

        
        
        
        let subs = User.sharedInstance.getSubscriptions()
        print("subs has length \(subs.count)")
        for sub in subs {
            let subscribedPC = SubscribedPodcast.fromPodcastSubscription(podcastSubscription: sub)
        }
        do {
            try managedObjectContext.save()
        } catch {
            print("error saving user data: \(error)")
        }
    }
}
