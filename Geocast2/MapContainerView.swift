//
//  MapContainerView.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/7/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class MapContainerView: UIView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for v in subviews {
            if let calloutView = v as? CalloutView {
                return calloutView
            }
        }
        return super.hitTest(point, withEvent: event)
    }
}
