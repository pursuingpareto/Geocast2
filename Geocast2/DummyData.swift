//
//  DummyData.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class DummyData: NSObject {
    
    static let location = CLLocation(latitude: 34.1561, longitude: -118.1319)
    
    class func getPodcast() -> Podcast {
        let podcast = Podcast(title: "Radiolab", collectionId: 152249110, feedUrl: NSURL(string: "http://feeds.wnyc.org/radiolab")!)
        return podcast
    }
    
    class func getEpisode() -> Episode {
        let urlString = "http://feeds.wnyc.org/~r/radiolab/~3/Uln3gPGuTNA/"
        let episode = Episode(podcast: getPodcast(), mp3URL: NSURL(string: urlString)!, title: "Birthstory")
        return episode
    }
    
    class func getTags() -> [Geotag] {
        var tags: [Geotag] = []
        let tag = Geotag(episode: getEpisode(), location: location, description: "Great Episode", locationName: "Apple Headquarters", address: "2 Infinte Loop, Cupertino, CA")
        tags.append(tag)
        return tags
    }
}
