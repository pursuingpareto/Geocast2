//
//  Episode.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

class Episode: NSObject {
    let podcast: Podcast
    let mp3URL: NSURL
    let title: String
    
    var duration: NSTimeInterval? = nil
    var summary: String? = nil
    var subtitle: String? = nil
    var iTunesSummary: String? = nil
    var pubDate: NSDate? = nil
    
    init(podcast: Podcast, mp3URL: NSURL, title: String) {
        self.podcast = podcast
        self.mp3URL = mp3URL
        self.title = title
    }
}