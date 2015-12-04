//
//  SubscribedPodcast+CoreDataProperties.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SubscribedPodcast {

    @NSManaged var subscriptionDate: NSDate!
    @NSManaged var title: String!
    @NSManaged var collectionId: NSNumber!
    @NSManaged var feedUrl: String!
    @NSManaged var thumbnailImageUrl: String?
    @NSManaged var largeImageUrl: String?
    @NSManaged var episodeCount: NSNumber?
    @NSManaged var lastUpdated: NSDate?
    @NSManaged var summary: String?
    @NSManaged var author: String?

}
