//
//  MapViewController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MapView!
    
    let tagManager = TagManager.sharedInstance
    private var currentTags: [Geotag] = []
    private let locationManager = CLLocationManager()
    private var mapViewRadius: CLLocationDistance = 5000
    private var defaultLocation = CLLocation(latitude: 34.1561, longitude: -118.1319)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startMonitoringSignificantLocationChanges()
        }
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        var location: CLLocation!
        if let loc = locationManager.location {
            location = loc
        } else {
            location = defaultLocation
        }
        centerMapOnLocation(location)
        updateView()
    }
    
    private func addTagsToMapView() {
        mapView.addAnnotations(currentTags)
    }
    
    private func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            mapViewRadius * 2.0, mapViewRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
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
            })
        })
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        centerMapOnLocation(manager.location!)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let geotag = annotation as? Geotag {
            let identifier = GeotagAnnotationView.reuseIdentifier
            var view: GeotagAnnotationView!
            if let v = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? GeotagAnnotationView {
                view = v
            } else {
                view = GeotagAnnotationView(annotation: geotag, reuseIdentifier: identifier)
            }
            view.canShowCallout = true
//            view.enabled = true
            let calloutView = CalloutView(frame: CGRectMake(0, 0, 300, 240))
            calloutView.setup(withGeotag: geotag)
            
            calloutView.playButton.addTarget(self, action: "playButtonPressed:", forControlEvents: .TouchUpInside)
            
            let widthConstraint = NSLayoutConstraint(item: calloutView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 300)
            calloutView.addConstraint(widthConstraint)
            
            let heightConstraint = NSLayoutConstraint(item: calloutView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 240)
            calloutView.addConstraint(heightConstraint)
            
            view.detailCalloutAccessoryView = calloutView
            return view
        } else {
            return nil
        }
    }
    
    func playButtonPressed(sender: UIButton!) {
        print("Play button pressed")
        print("sender superview is \(sender.superview)")
        guard let selected = mapView.selectedAnnotations.first as? Geotag else {
            print("Error: nothing is selected on map")
            return
        }
        let episode = selected.episode
        let userData = User.sharedInstance.getUserData(forEpisode: episode)
        PodcastPlayer.sharedInstance.loadEpisode(episode, withUserEpisodeData: userData, completion: {
            item in
        })
        tabBarController?.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue

    }
    
//    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
//        var viewC = CalloutView(frame: CGRectMake(0, 0, 150, 150))
//        viewC.backgroundColor = UIColor.blackColor()
//        
//        view.addSubview(viewC)
//        viewC.center = CGPointMake(viewC.bounds.size.width*0.1, -viewC.bounds.size.height*0.5)
//        view.sizeToFit()
//        mapView.bringSubviewToFront(view)
//    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.selectedAnnotations = [view.annotation as! Geotag]
    }
    
}