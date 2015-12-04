//
//  SubscribedPodcast.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import CoreData

@objc
class SubscribedPodcast: NSManagedObject {

    class func fromPodcastSubscription(podcastSubscription sub: PodcastSubscription) -> SubscribedPodcast {
        print("getting subscribed podcast from pcsub")
        
        let context = PersistenceManager.sharedInstance.managedObjectContext
        
        print("context is \(context)")
        
        let sp = NSEntityDescription.insertNewObjectForEntityForName("SubscribedPodcast", inManagedObjectContext: context) as! SubscribedPodcast
        let pc = sub.podcast
        
        sp.subscriptionDate = sub.subscriptionDate
        sp.title = pc.title
        sp.collectionId = pc.collectionId
        sp.feedUrl = pc.feedUrl.path
        sp.thumbnailImageUrl = pc.thumbnailImageURL?.path
        sp.largeImageUrl = pc.largeImageURL?.path
        sp.episodeCount = pc.episodeCount
        sp.lastUpdated = pc.lastUpdated
        sp.summary = pc.summary
        sp.author = pc.author
//        do {
//            try context.save()
//        } catch {
//            print(error)
//        }
        do {
            print("saving 1 USER DATA")

            try context.save()
        } catch {
            print(error)
        }
        return sp
    }
    
    func toPodcastSubscription() -> PodcastSubscription {
        let pc = Podcast(title: self.title, collectionId: Int(self.collectionId) , feedUrl: NSURL(string: self.feedUrl)!)
        if let thumbURL = self.thumbnailImageUrl {
            pc.thumbnailImageURL = NSURL(string: thumbURL)
        }
        if let largeURL = self.largeImageUrl {
            pc.largeImageURL = NSURL(string: largeURL)
        }
        if let count = self.episodeCount as? Int {
            pc.episodeCount = count
        }
        if let lastUpdate = self.lastUpdated {
            pc.lastUpdated = lastUpdate
        }
        if let sum = self.summary {
            pc.summary = sum
        }
        if let auth = self.author {
            pc.author = auth
        }
        
        let sub = PodcastSubscription(podcast: pc)
        sub.subscriptionDate = self.subscriptionDate
        
        return sub
        
        //
    }

}
