//
//  PersistenceManager.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import CoreData

class PersistenceManager: NSObject {
    
    static let sharedInstance = PersistenceManager()
    
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
    
    
//    func fetchEpisodeData(forEpisodesInSubscription subscription: SubscribedPodcast) -> [EpisodeWithStats]? {
//        
//    }
    
    func updateUserWithStoredData() {
        print("updating user with stored data...")
        if let subscribedPCs = fetchSubscriptionData() {
            var userSubs = [Int: PodcastSubscription]()
            for subscribedPC in subscribedPCs {
                let pcSub = subscribedPC.toPodcastSubscription()
                userSubs[pcSub.podcast.collectionId] = pcSub
            }
            if let epsWithStats = fetchEpisodeData() {
                print("  epsWithStats is \(epsWithStats)")
                for ep in epsWithStats {
                    let userEpisodeData = ep.toUserEpisodeData()
                    let podcastSub = (ep.podcast as! SubscribedPodcast).toPodcastSubscription()
                    let collectionId = podcastSub.podcast.collectionId
                    if let sub: PodcastSubscription = userSubs[collectionId] {
                        // this podcast has already been added to subscriptions
                        userSubs[collectionId]?.episodeData[userEpisodeData.episode.mp3URL] = userEpisodeData
                    }
                }
                print("  about to wipe subscriptions and update")
                User.sharedInstance.wipeSubscriptionsAndUpdate(withSubscriptions: userSubs)
            }
        }
    }
    
    func saveAllUserData() {
        var fetchRequest = NSFetchRequest(entityName: "SubscribedPodcast")
        var deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedObjectContext.persistentStoreCoordinator?.executeRequest(deleteRequest, withContext: managedObjectContext)
        } catch let error as NSError {
            print("error saving user data: \(error)")
        }
        
        fetchRequest = NSFetchRequest(entityName: "EpisodeWithStats")
        deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedObjectContext.persistentStoreCoordinator?.executeRequest(deleteRequest, withContext: managedObjectContext)
        } catch let error as NSError {
            print("error saving user data: \(error)")
        }
        
        let subs = User.sharedInstance.getSubscriptions()
        print("subs has length \(subs.count)")
        for sub in subs {
            let subscribedPC = SubscribedPodcast.fromPodcastSubscription(podcastSubscription: sub)
            print("got subscribedPC with title \(subscribedPC.title)")
        }
        do {
            print("SAVING USER DATA")
            print("CONTEXT is \(managedObjectContext)")
            try managedObjectContext.save()
        } catch {
            print(error)
        }
    }
}
