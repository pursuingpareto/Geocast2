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
    
    @IBOutlet private weak var mapView: MKMapView!
    
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
            print("getting current tags")
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
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? GeotagAnnotationView {
                dequeuedView.annotation = geotag
                return dequeuedView
            } else {
                let view = GeotagAnnotationView(annotation: geotag, reuseIdentifier: identifier)
                return view
            }
        } else {
            return nil
        }
    }
}