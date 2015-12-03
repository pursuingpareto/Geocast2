//
//  UserEpisodeData.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import CoreMedia

class UserEpisodeData: NSObject {
    var lastPlayedAt: NSDate?
    var fractionListenedTo: Float! = 0.0
    var lastPlayedTimestamp: CMTime = kCMTimeZero
    let episode: Episode
    
    init(episode: Episode) {
        self.episode = episode
    }
    
    func update(withCurrentPlayTime time: NSTimeInterval) {
        self.lastPlayedAt = NSDate()
    }
}