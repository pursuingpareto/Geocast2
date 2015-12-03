//
//  TagManager.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import MapKit

class TagManager : NSObject {
    static let sharedInstance = TagManager()
    
    func addTag(forEpisode episode: Episode, atLocation location: CLLocation, withName name: String, withDescription description: String, withAddress address: String) {
        // TODO : Implement
    }
    
    func getTags(nearLocation location: CLLocation) -> [Geotag] {
        // TODO : Implement
        return DummyData.getTags()
    }
}
