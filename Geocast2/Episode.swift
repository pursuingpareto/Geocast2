//
//  Episode.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import Parse

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
    
    init(pfEpisode: PFObject){
        self.podcast = Podcast(pfPodcast: pfEpisode["podcast"] as! PFObject)
        self.title = pfEpisode["title"] as! String
        self.mp3URL = NSURL(string: (pfEpisode["mp3Url"] as! String))!
        if let duration = pfEpisode["duration"] as? NSTimeInterval {
            self.duration = duration
        }
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.pubDate = df.dateFromString((pfEpisode["pubDate"] as! String))
        self.summary = pfEpisode["summary"] as? String
        self.iTunesSummary = pfEpisode["itunesSummary"] as? String
        self.subtitle = pfEpisode["itunesSubtitle"] as? String
    }
    
    func saveToParse(withPFPodcast pfPodcast: PFObject) -> PFObject {
        let pfEpisode = PFObject(className: "Episode")
        pfEpisode["title"] = title
        pfEpisode["mp3Url"] = mp3URL.absoluteString
        pfEpisode["podcast"] = pfPodcast
        if let dur = duration {
            pfEpisode["duration"] = dur
        }
        if let pd = pubDate {
            let df = NSDateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            pfEpisode["pubDate"] = df.stringFromDate(pd)
        }
        if let sum = summary {
            pfEpisode["summary"] = sum
            pfEpisode["itunesSummary"] = summary
        }
        if iTunesSummary != nil {
            pfEpisode["itunesSummary"] = iTunesSummary!
        }
        if let sub = subtitle {
            pfEpisode["itunesSubtitle"] = sub
        }
        pfEpisode.saveInBackground()
        return pfEpisode
    }
    
}

func ==(left: Episode, right: Episode) -> Bool {
    return left.mp3URL == right.mp3URL
}

func !=(left: Episode, right: Episode) -> Bool {
    return !(left == right)
}