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
        let context = PersistenceManager.sharedInstance.managedObjectContext
        
        let sp = NSEntityDescription.insertNewObjectForEntityForName("SubscribedPodcast", inManagedObjectContext: context) as! SubscribedPodcast
        let pc = sub.podcast
        
        sp.subscriptionDate = sub.subscriptionDate
        sp.title = pc.title
        sp.collectionId = pc.collectionId
        sp.feedUrl = "\(pc.feedUrl)"
        if pc.thumbnailImageURL != nil {
            sp.thumbnailImageUrl = "\(pc.thumbnailImageURL)"
        } else {
            sp.thumbnailImageUrl = nil
        }
        if pc.largeImageURL != nil {
            sp.largeImageUrl = "\(pc.largeImageURL)"
        } else {
            sp.largeImageUrl = nil
        }
        
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
