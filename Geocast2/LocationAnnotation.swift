//
//  LocationAnnotation.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/10/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class LocationAnnotation: NSObject, MKAnnotation {
    
    var placemark: MKPlacemark!
    var coordinate: CLLocationCoordinate2D {
        get {
           return self.placemark.coordinate
        }
    }
    
}

//extension LocationAnnotation: MKAnnotation {
//    var coordinate: CLLocationCoordinate2D {
//        return placemark.location!.coordinate
//    }
//}