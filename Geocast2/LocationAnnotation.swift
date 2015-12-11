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
    
    var title: String? {
        return getName(fromPlacemark: placemark)
    }
    
    var subtitle: String? {
        return getAddress(fromPlacemark: placemark)
    }
    
    
    var coordinate: CLLocationCoordinate2D {
        get {
           return self.placemark.coordinate
        }
    }
    
    func getName(fromPlacemark pm: MKPlacemark) -> String? {
        var text: String!
        if let areaOfInterest = pm.areasOfInterest?.first {
            text = areaOfInterest
        } else {
            text = pm.name
        }
        return text
    }
    
    func getAddress(fromPlacemark pm: MKPlacemark) -> String? {
        var address: String = ""
        if let addressLines = pm.addressDictionary!["FormattedAddressLines"] as? [String]{
            for line in addressLines {
                address += "\(line) "
            }
            return address
        } else {
            return nil
        }
    }
    
}

//extension LocationAnnotation: MKAnnotation {
//    var coordinate: CLLocationCoordinate2D {
//        return placemark.location!.coordinate
//    }
//}