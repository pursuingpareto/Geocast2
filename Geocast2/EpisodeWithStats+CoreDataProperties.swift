//
//  EpisodeWithStats+CoreDataProperties.swift
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

extension EpisodeWithStats {

    @NSManaged var mp3Url: String!
    @NSManaged var title: String!
    @NSManaged var totalSeconds: NSNumber?
    @NSManaged var summary: String?
    @NSManaged var subtitle: String?
    @NSManaged var pubDate: NSDate?
    @NSManaged var lastPlayedAt: NSDate?
    @NSManaged var fractionListenedTo: NSNumber!
    @NSManaged var lastPlayedTimestamp: NSNumber!
    @NSManaged var itunesSummary: String?
    @NSManaged var podcast: NSManagedObject!

}
