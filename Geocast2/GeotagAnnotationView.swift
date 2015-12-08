//
//  GeotagAnnotation.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class GeotagAnnotationView : MKPinAnnotationView {
    
    static let reuseIdentifier = "geotagViewIdentifier"
    
//    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
//        print("performing hit test")
//        for v in subviews {
//            print("subview is \(v)")
//            if let view = v as? CalloutView {
//                let p = convertPoint(point, toView: view)
//                let retView = view.hitTest(point, withEvent: event)
//                print("RETURN VIEW IS \(retView)\n")
//                return retView
//            }
//        }
//        let returnView = super.hitTest(point, withEvent: event)
//        print("returnView is \(returnView)\n")
//        return returnView
//    }
    
//    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
//        if selected {
//            for v in subviews {
//                if v.pointInside(point , withEvent: event) {
//                    return true
//                }
//            }
//        } else {
//            return super.pointInside(point, withEvent: event)
//        }
//        return super.pointInside(point , withEvent: event)
//    }
    
}
