//
//  PlayerSliderView.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/18/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class PlayerSliderView: UISlider {
    override func trackRectForBounds(bounds: CGRect) -> CGRect {
        let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: 6.0))
        super.trackRectForBounds(customBounds)
        return customBounds
    }
}
