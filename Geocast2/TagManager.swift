//
//  TagManager.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/3/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import MapKit
import Parse

class TagManager : NSObject {
    
    static let sharedInstance = TagManager()
    
    func addTag(forEpisode episode: Episode, atLocation location: CLLocation, withName name: String, withDescription description: String, withAddress address: String, withRadius radius: CLLocationDistance) {
        let annotation = Geotag(episode: episode, location: location, description: description, locationName: name, address: address, tagRadius: radius)
        var query = PFQuery(className: "Podcast")
        query.whereKey("collectionId", equalTo: episode.podcast.collectionId)
        query.findObjectsInBackgroundWithBlock({
            (objects: [PFObject]?, error: NSError?) -> Void in
            var pfPodcast: PFObject!
            if error == nil && objects?.count > 0 {
                // podcast exists
                pfPodcast = objects![0]
            } else {
                pfPodcast = episode.podcast.saveToParse()
            }
            query = PFQuery(className: "Episode")
            query.whereKey("mp3Url", equalTo: episode.mp3URL.absoluteString )
            query.findObjectsInBackgroundWithBlock({
                (objects: [PFObject]?, error: NSError?) -> Void in
                var pfEpisode: PFObject!
                if (error == nil && objects?.count > 0) {
                    pfEpisode = objects![0]
                } else {
                    pfEpisode = episode.saveToParse(withPFPodcast: pfPodcast)
                }
                let pfTag = PFObject(className: "Geotag")
                pfTag["podcast"] = pfPodcast
                pfTag["episode"] = pfEpisode
                pfTag["user"] = PFUser.currentUser()!
                let point = PFGeoPoint(location: location)
                pfTag["location"] = point
                pfTag["locationName"] = name
                pfTag["tagDescription"] = description
                pfTag["address"] = address
                pfTag["locationRadius"] = radius
                print("about to save tag")
                pfTag.saveInBackground()
            })
        })
    }
    
    func getTags(nearLocation location: CLLocation) -> [Geotag] {
        let query = PFQuery(className: "Geotag")
        let geoPoint = PFGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        query.whereKey("location", nearGeoPoint: geoPoint)
        query.includeKey("podcast")
        query.includeKey("episode")
        var tags: [Geotag] = []
        do {
            let tagObjects = try query.findObjects() as [PFObject]
            for tagObject in tagObjects {
                let pfPodcast = tagObject["podcast"] as! PFObject
                let pfEpisode = tagObject["episode"] as! PFObject
                let pfLocation = tagObject["location"] as! PFGeoPoint
                let pfAddress = tagObject["address"] as? String
                let pfDescription = tagObject["tagDescription"] as? String
                let pfLocationName = tagObject["locationName"] as! String
                let pfLocationRadius = tagObject["locationRadius"] as! CLLocationDistance
                let episode = Episode(pfEpisode: pfEpisode)
                let tag = Geotag(episode: Episode(pfEpisode: pfEpisode), location: CLLocation(latitude: pfLocation.latitude, longitude: pfLocation.longitude), description: pfDescription, locationName: pfLocationName, address: pfAddress, tagRadius: pfLocationRadius)
                tags.append(tag)
            }
        } catch {
            print("errror caught")
        }
        return tags
    }
}
