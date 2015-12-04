//
//  Subscription.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

class PodcastSubscription: NSObject {
    var subscriptionDate: NSDate
    let podcast: Podcast
    var episodeData = [NSURL : UserEpisodeData?]()
    
    init(podcast: Podcast) {
        self.podcast = podcast
        self.subscriptionDate = NSDate()
    }
    
}