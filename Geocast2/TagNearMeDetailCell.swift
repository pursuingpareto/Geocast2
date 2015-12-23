//
//  TagNearMeDetail.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/11/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class TagNearMeDetailCell: UITableViewCell {
    
    var geotag: Geotag? = nil

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var podEpLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var playButton: UIButton!
    
//    func setup(withTagNearMeCell cell: TagNearMeCell) {
//        podcastImageView.image = cell.podcastImageView.image
//        distanceLabel.text = cell.durationLabel.text
//        podEpLabel.text = cell.addressLabel.text
//        locationLabel.text = cell.podEpLabel.text
//    }
    
    @IBAction func segmentedControlSelected(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.textView.text = self.geotag?.tagDescription
        case 1:
            self.textView.text = self.geotag?.episode.iTunesSummary?.removeHTML()
        default:
            return
        }
    }
}
