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
    
    private var imageCache = [NSURL : UIImage]()
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func fetchSubscriptionData() -> [SubscribedPodcast]? {
        let subscriptionRequest = NSFetchRequest(entityName: "SubscribedPodcast")
//        let subscriptionReq = NSPersistentStoreRequest()
//        subscriptionReq.affectedStores = managedObjectContext.persistentStoreCoordinator?.persistentStores
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(subscriptionRequest) as? [SubscribedPodcast]
            return fetchResults
        } catch {
            print("error")
            return nil
        }
    }
    
    func attemptToGetImageFromCache(withURL url: NSURL?, completion: (image: UIImage?) -> Void) {
        guard let url = url else {
            print("invalid URL sent to attemptToGetImageFromCache")
            return
        }
        if let img = imageCache[url] {
            completion(image: img)
        } else {

            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
                if error == nil {
                    var image = UIImage(data: data!)
                    self.imageCache[url] = image
                    completion(image: image)
                } else {
                    print("error getting image was \(error)\n\ndata is \(data)")
                    completion(image: nil)
                }
            })
            task.resume()
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
            print("...userSubs has length \(userSubs.count)")
            if let epsWithStats = fetchEpisodeData() {
                for ep in epsWithStats {
                    let userEpisodeData = ep.toUserEpisodeData()
                    let podcastSub = (ep.podcast as! SubscribedPodcast).toPodcastSubscription()
                    let collectionId = podcastSub.podcast.collectionId
                    if let sub: PodcastSubscription = userSubs[collectionId] {
                        // this podcast has already been added to subscriptions
                        userSubs[collectionId]?.episodeData[userEpisodeData.episode.mp3URL] = userEpisodeData
                    }
                }
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
        }
        do {
            try managedObjectContext.save()
        } catch {
            print("error saving user data: \(error)")
        }
        
        // TODO : Remove this for production
        
        if let subs = fetchSubscriptionData() {
            print("SubscribedPodcasts count is \(subs.count)")
        } else {
            print("subscribedPodcasts is nil...")
        }
        
        if let epsWithStats = fetchEpisodeData() {
            print("epsWithStats count is \(epsWithStats.count)")
        } else {
            print("eps with stats is nil...")
        }
//        do {
//            let saveCount = try managedObjectContext.persistentStoreCoordinator?.executeRequest(fetchRequest, withContext: managedObjectContext).count
//            print("savecount is \(saveCount)")
//        } catch {
//            print("error with test fetch: \(error)")
//        }
    }
}
