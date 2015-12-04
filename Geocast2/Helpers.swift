//
//  Helpers.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/2/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation

extension CMTime {
    func asString() -> String {
        let totalSeconds = self.seconds
        let hours = Int(floor(totalSeconds / 3600))
        let mins = Int(floor((totalSeconds % 3600) / 60))
        let secs = Int(floor((totalSeconds % 3600) % 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, mins, secs)
        } else {
            return String(format: "%02i:%02i", mins, secs)
        }
    }
}
