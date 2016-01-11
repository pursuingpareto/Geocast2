//
//  MapViewController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit
import CoreMedia
import Kingfisher

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private let iOS8TagSegueIdentifier = "iOS8TagSegueIdentifier"
    
    let tagManager = TagManager.sharedInstance
    private var currentTags: [Geotag] = []
    private let locationManager = CLLocationManager()
    private var mapViewRadius: CLLocationDistance = 5000
    private var defaultLocation = CLLocation(latitude: 34.1561, longitude: -118.1319)
    private var initialLocationDetermined = false
    
    private var selectedIndexPath: NSIndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("about to request authorization")
        self.locationManager.requestWhenInUseAuthorization()
        print("got authorization")
        if CLLocationManager.locationServicesEnabled() {
            print("location services enabled!")
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        } else {
            print("location services not enabled")
        }
        

        
        mapView.delegate = self
        mapView.showsUserLocation = true
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnectedToNetwork() {
            let alertController = Reachability.makeNoConnectionAlert()
            alertController.message = "Episodes near you are only available when you have a network connection."
            presentViewController(alertController, animated: true, completion: nil)
        }
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
        updateView()
        centerMapOnLocation(CLLocation(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude))
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("preparing for segue with identifier \(segue.identifier)")
        if segue.identifier! == iOS8TagSegueIdentifier {
            let destVC = segue.destinationViewController as! iOS8TagViewController
            let geotag = mapView.selectedAnnotations.first! as! Geotag
            print("assigning geotag to destVC \(geotag)")
            destVC.geotag = geotag
        } else if let vc = segue.destinationViewController as? PlayerViewController {
            vc.shouldPlay = true
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    private func addTagsToMapView() {
        mapView.addAnnotations(currentTags)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        print("centering map on location")
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            mapViewRadius * 2.0, mapViewRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.hidden = false
            tableView.hidden = true
        case 1:
            mapView.hidden = true
            tableView.hidden = false
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        default:
            break
        }
    }
    private func updateView() {
        var location: CLLocation!
        if let loc = locationManager.location {
            location = loc
        } else {
            location = defaultLocation
        }
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0), {
            self.currentTags = self.tagManager.getTags(nearLocation: location)
            dispatch_async(dispatch_get_main_queue(), {
                self.addTagsToMapView()
                self.tableView.reloadData()
            })
        })
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (initialLocationDetermined || locations.count == 0 ) {
            return
        } else {
            initialLocationDetermined = true
            centerMapOnLocation(locations.first!)
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("authorization status changed to \(status)")
        switch status {
        case .AuthorizedWhenInUse:
            manager.startMonitoringSignificantLocationChanges()
            manager.startUpdatingLocation()
            if let loc = manager.location {
                print("...got location")
                centerMapOnLocation(loc)
            } else {
                print("...did not get location")
            }
        default:
            return
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("trying to get viewForAnnotation")
        if let geotag = annotation as? Geotag {
            let identifier = GeotagAnnotationView.reuseIdentifier
            var view: GeotagAnnotationView!
            if let v = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? GeotagAnnotationView {
                view = v
            } else {
                view = GeotagAnnotationView(annotation: geotag, reuseIdentifier: identifier)
            }
            
            if #available(iOS 9, *) {
                view.pinTintColor = UIColor.blackColor()
                view.canShowCallout = true
                //            view.enabled = true
                let calloutView = CalloutView(frame: CGRectMake(0, 0, 320, 290))
                calloutView.setup(withGeotag: geotag)
                
                calloutView.playButton.addTarget(self, action: "playButtonPressed:", forControlEvents: .TouchUpInside)
                
                let widthConstraint = NSLayoutConstraint(item: calloutView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 320)
                calloutView.addConstraint(widthConstraint)
                
                let heightConstraint = NSLayoutConstraint(item: calloutView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 290)
                calloutView.addConstraint(heightConstraint)
                
                view.detailCalloutAccessoryView = calloutView
                return view
            } else {
                return view
            }
        } else {
            return nil
        }
    }
    
    func detailCellPlayButtonPressed(sender: UIButton) {
        print("play episode pressed")
        let ip = sender.tag
        let geotag = currentTags[ip]
        switchToPlayer(withEpisode: geotag.episode)
    }
    
    private func switchToPlayer(withEpisode episode: Episode) {
        let vc = tabBarController!.viewControllers![MainTabController.TabIndex.playerIndex.rawValue] as! PlayerViewController
        vc.shouldPlay = true
        let userEpisodeData: UserEpisodeData? = User.sharedInstance.getUserData(forEpisode: episode)
        PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userEpisodeData, completion: {(item) in
        })
        tabBarController?.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
    }
    
    func playButtonPressed(sender: UIButton!) {
        print("Play button pressed")
        print("sender superview is \(sender.superview)")
        guard let selected = mapView.selectedAnnotations.first as? Geotag else {
            print("Error: nothing is selected on map")
            return
        }
        let episode = selected.episode
        switchToPlayer(withEpisode: episode)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.selectedAnnotations = [view.annotation as! Geotag]
        if #available(iOS 9, *) {
            
        } else {
            performSegueWithIdentifier(iOS8TagSegueIdentifier, sender: self)
        }
    }
}

extension MapViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let geotag = currentTags[indexPath.row]
        let episode = geotag.episode
        let coordinate = geotag.coordinate
        let coord = mapView.userLocation.coordinate
        let currentPosition = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let podcastTitle = episode.podcast.title
        let episodeTitle = episode.title
        
        let distance = currentPosition.distanceFromLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
      
        let cell = tableView.dequeueReusableCellWithIdentifier("tagCell", forIndexPath: indexPath) as! TagNearMeCell
        
        cell.locationNameLabel.text = geotag.locationName
        cell.addressLabel.text = geotag.address
        cell.distanceLabel.text = distance.toShortString()
        cell.podcastLabel.text = podcastTitle
        cell.episodeLabel.text = episodeTitle
        cell.textView.text = episode.summary
        cell.playButton?.addTarget(self, action: "detailCellPlayButtonPressed:", forControlEvents: .TouchUpInside)
        cell.playButton?.tag = indexPath.row
        if selectedIndexPath == indexPath {
            cell.textView.numberOfLines = 0
            cell.textView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        } else {
            cell.textView.numberOfLines = 1
            cell.textView.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        }
        
        if let url = episode.podcast.thumbnailImageURL {
            cell.podcastImageView.kf_showIndicatorWhenLoading = true
            cell.podcastImageView.kf_setImageWithURL(url)
        }
        return cell
    }
}

extension MapViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 172.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected row at \(indexPath.row)")
        if selectedIndexPath == indexPath {
            selectedIndexPath = nil
            tableView.reloadRowsAtIndexPaths(
                [indexPath],
                withRowAnimation:UITableViewRowAnimation.Fade)
            tableView.deselectRowAtIndexPath(indexPath, animated:false)
            return
        }
        if selectedIndexPath != nil {
            let pleaseRedrawMe = selectedIndexPath!
            selectedIndexPath = indexPath
            tableView.reloadRowsAtIndexPaths(
                [pleaseRedrawMe, indexPath],
                withRowAnimation:UITableViewRowAnimation.Fade)
            return
        }
        selectedIndexPath = indexPath
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
}