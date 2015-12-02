//
//  PodcastPlayer.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import AVFoundation

class PodcastPlayer: AVPlayer {
//    var episode: Episode?
    class var sharedInstance: PodcastPlayer {
        struct Singleton {
            static let instance = PodcastPlayer()
        }
        return Singleton.instance
    }
}