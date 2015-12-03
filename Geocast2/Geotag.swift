//
//  Geotag.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import MapKit

class Geotag: NSObject, MKAnnotation {
    
    static var defaultLocationRadius: CLLocationDistance = 100
    
    var coordinate: CLLocationCoordinate2D { return location.coordinate }
    var title: String? { return episode.title }
    var subtitle: String? { return locationName }
    
    let episode: Episode!
    let location: CLLocation!
    let tagDescription: String!
    let locationName: String?
    let address: String?
    let locationRadius: CLLocationDistance!
    
    init(episode: Episode, location: CLLocation, description: String, locationName: String?, address: String?, tagRadius:CLLocationDistance = Geotag.defaultLocationRadius) {
        self.episode = episode
        self.location = location
        self.tagDescription = description
        self.locationName = locationName
        self.address = address
        self.locationRadius = tagRadius
    }
}