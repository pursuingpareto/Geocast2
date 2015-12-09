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

extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}