//
//  ITunesAPIController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

protocol ITunesAPIControllerDelegate {
    func didReceivePodcasts(podcasts: [Podcast])
}

class ITunesAPIController {
    
    var delegate: ITunesAPIControllerDelegate
    
    init(delegate: ITunesAPIControllerDelegate) {
        self.delegate = delegate
    }
    
    private func getFromITunes(path: String) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url = NSURL(string: path)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!, completionHandler: {data, response, error -> Void in
            if(error != nil) {
                // If there is an error in the web request, print it to the console
                print(error!.localizedDescription)
            }
            else {
                if let data = data {
                    let jsonResult = (try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
                    let results: NSArray = jsonResult["results"] as! NSArray
                    var podcasts = [Podcast]()
                    podcasts = Podcast.podcastsWithJSON(results)
                    self.delegate.didReceivePodcasts(podcasts)
                }
            }
        })
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        task.resume()
    }
    
    func searchPodcasts(searchTerm: String) {
        // The iTunes API wants multiple terms separated by + symbols, so replace spaces with + signs
        let itunesSearchTerm = searchTerm.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        // Now escape anything else that isn't URL-friendly
        if let escapedSearchTerm = itunesSearchTerm.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            let urlPath = "https://itunes.apple.com/search?term=\(escapedSearchTerm)&media=podcast"
            getFromITunes(urlPath)
        }
    }
    
    func lookupPodcasts(collectionIds: [Int]) {
        let id_string = collectionIds.map {($0.description)}.joinWithSeparator("," )
        getFromITunes("https://itunes.apple.com/lookup?media=podcast&id=\(id_string)")
    }
}