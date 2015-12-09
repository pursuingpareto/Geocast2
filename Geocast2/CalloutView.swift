//
//  CalloutView.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/7/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import Kingfisher

class CalloutView: UIView {
    var view: UIView!

    @IBOutlet weak var playButton: UIButton!
    
    var geotag: Geotag!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
    @IBOutlet weak var secondaryLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            setup(withGeotag: geotag)
        case 1:
            setupEpisodeView()
        case 2:
            setupPodcastView()
        default:
            break
        }
    }
    
    func setup(withGeotag tag: Geotag) {
        self.geotag = tag
        
        mainLabel.hidden = false
        mainLabel.numberOfLines = 2
        if let name = tag.locationName {
            mainLabel.text = name
        } else {
            mainLabel.text = "Location for \(tag.episode.title)"
        }
        
        secondaryLabel.hidden = false
        secondaryLabel.numberOfLines = 2
        if let address = tag.address {
            secondaryLabel.text = address
        } else {
            secondaryLabel.hidden = true
        }
        
        textView.text = tag.tagDescription
        
        if let url = tag.episode.podcast.largeImageURL {
            imageView.kf_showIndicatorWhenLoading = true
            imageView.kf_setImageWithURL(url)
        } else {
            // TODO : handle default images
        }
    }
    
    func setupEpisodeView() {
        mainLabel.hidden = false
        secondaryLabel.hidden = false
        mainLabel.text = geotag.episode.title
        secondaryLabel.text = geotag.episode.podcast.title
        if let summary = geotag.episode.summary {
            textView.text = summary
        } else if let summary = geotag.episode.iTunesSummary {
            textView.text = summary
        } else if let summary = geotag.episode.subtitle {
            textView.text = summary
        } else {
            textView.text = "No summary for this episode, but I bet it's a good one 👍"
        }
    }
    
    func setupPodcastView() {
        mainLabel.hidden = false
        secondaryLabel.hidden = false
        mainLabel.text = geotag.episode.title
        secondaryLabel.text = geotag.episode.podcast.title
        let podcast = geotag.episode.podcast
        if let summary = podcast.summary {
            textView.text = summary
        } else {
            textView.text = "No summary information for \(podcast.title) 😧. I'm sure it's a great Podcast though!"
        }
        
    }
    
    override init(frame: CGRect) {
        // 1. setup any properties here
        
        // 2. call super.init(frame:)
        super.init(frame: frame)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "CalloutView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
}
