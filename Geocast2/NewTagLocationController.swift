//
//  NewTagLocationController.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/10/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit


protocol LocationInformationUpdating {
    func receivedLocationInformation(fromViewController: UIViewController, coordinate: CLLocationCoordinate2D, address: String?, name: String?) -> Void

}

class NewTagLocationController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var transformHeight: CGFloat!
    var selectedIndexPath: NSIndexPath? = nil
    
    var delegate: LocationInformationUpdating?
    
    private var hasReceivedUserLocation = false
    private let zoomWidth: CLLocationDistance = 2000
    private let unzoomWidth: CLLocationDistance = 20000

    private var locationsFound = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Location"
        definesPresentationContext = false
        searchBar.placeholder = "Search for location or address"
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        print("New Tag Location viewDidLoad")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
        super.touchesBegan(touches , withEvent: event)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func updateViewWithNewLocations() {
        dispatch_async(dispatch_get_main_queue(), {
            self.updateMapViewTags()
            self.tableView.setEditing(false, animated: true)
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let coord  = mapView.userLocation.coordinate
        let region = MKCoordinateRegionMakeWithDistance(coord, unzoomWidth, unzoomWidth)
        mapView.setRegion(region, animated: true)
        
    }
    
    func getAddress(fromPlacemark pm: MKPlacemark) -> String {
        var address: String = ""
        if let addressLines = pm.addressDictionary!["FormattedAddressLines"] as? [String]{
            for line in addressLines {
                address += "\(line) "
            }
            return address
        } else if pm.name != nil {
            return pm.name!
        } else {
            return ""
        }
    }
    
    func getName(fromPlacemark pm: MKPlacemark) -> String? {
        var text: String!
        if let areaOfInterest = pm.areasOfInterest?.first {
            text = areaOfInterest
        } else {
            text = pm.name
        }
        return text
    }
    
    func search(forString str: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler({
            (response: MKLocalSearchResponse?, error: NSError?) in
            
            guard error == nil else {
                print("error searching for location was \(error)")
                return
            }
            
            guard let response = response else {
                print("response was nil while searching for location")
                return
            }
            self.locationsFound = response.mapItems as! [MKMapItem]
            self.updateViewWithNewLocations()
        })
    }
    
    func updateMapViewTags() {
        
        for ann in mapView.annotations {
            if (ann is MKUserLocation) {
                continue
            } else {
                mapView.removeAnnotation(ann)
            }
        }
        
        var newAnnotations = [LocationAnnotation]()
        for location in locationsFound {
            let ann = LocationAnnotation()
            ann.placemark = location.placemark
            newAnnotations.append(ann)
        }
        mapView.addAnnotations(newAnnotations)
    }
}

extension NewTagLocationController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        let fadeAnimation = CATransition()
        fadeAnimation.duration = 0.25
        fadeAnimation.type = kCATransitionFade
        
//        self.navigationItem.title = ""
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.transformHeight = self.navigationController!.navigationBar.bounds.height
            let transform = CGAffineTransformMakeTranslation(0, -self.transformHeight)
            self.view.frame.origin.y -= self.transformHeight
            self.navigationController!.navigationBar.frame.origin.y -= self.transformHeight
            self.setNavVisibile(false)
            }, completion: {
                completed in
        })
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        print("Search Bar text did end editing")
        setNavVisibile(true)
        
        let fadeAnimation = CATransition()
        fadeAnimation.duration = 0.25
        fadeAnimation.type = kCATransitionFade
//        self.navigationItem.title = "Add Location"
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.navigationController!.navigationBar.frame.origin.y += self.transformHeight
            self.view.frame.origin.y += self.transformHeight
            }, completion: {
                completed in
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("about to search for \(searchText)")
        search(forString: searchText)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text {
            search(forString: text)
        }
        searchBar.delegate!.searchBarTextDidEndEditing!(searchBar)
        searchBar.resignFirstResponder()
    }
    
    func setNavVisibile(visible:Bool) {
        print("setting nav visible: \(visible)")
        let alpha: CGFloat = visible ? 1.0 : 0.0
        navigationController?.navigationBar.layer.opacity = Float(alpha)
        navigationItem.titleView?.alpha = alpha
        navigationItem.hidesBackButton = !visible

    }
}

extension NewTagLocationController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationsFound.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath) as! LocationCell
        let location = locationsFound[indexPath.row]
        let pm = location.placemark
        
        // get address
        let address = getAddress(fromPlacemark: pm)
        cell.addressLabel.text = address
        
        cell.nameLabel.text = getName(fromPlacemark: pm)
        return cell
    }
}

extension NewTagLocationController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("did select row at indexPath \(indexPath)")
        selectedIndexPath = indexPath
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        
        let location = locationsFound[indexPath.row]
        let region = MKCoordinateRegionMakeWithDistance(location.placemark.coordinate, zoomWidth, zoomWidth)
        mapView.setRegion(region, animated: true)
        
        let lat = location.placemark.coordinate.latitude
        let long = location.placemark.coordinate.longitude
        
        for annotation in mapView.annotations {
            let c = annotation.coordinate
            if (c.latitude == lat && c.longitude == long) {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
//        tableView.setEditing(true, animated: true)
    }
    
//    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
//        let cell = tableView.dataSource!.tableView(tableView, cellForRowAtIndexPath: indexPath)
//        print("cell editing style is \(cell.editingStyle.rawValue)")
//        tableView.setEditing(true, animated: true)
//    }
    
//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        print("can edit?")
//        print("...yes")
//        if ( locationsFound.count > 0 && selectedIndexPath != nil ){
//            print("indexPath for selected row: \(selectedIndexPath)")
//            print("indexPath to compare is   : \(indexPath)")
//            if indexPath == selectedIndexPath {
//                print("...yes")
//                selectedIndexPath = nil
//                return true
//            } else {
//                print("...no")
//                return false
//            }
//        } else {
//            print("...no")
//            return false
//        }
//    }
    
//    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        print("editing style: \(UITableViewCellEditingStyle.Insert)")
////        return UITableViewCellEditingStyle.Insert
//        return UITableViewCellEditingStyle.None
//    }
    
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        print("trying to commit editing style!")
//        let location = locationsFound[indexPath.row]
//        let coord = location.placemark.coordinate
//        let name = getName(fromPlacemark: location.placemark)
//        let address = getAddress(fromPlacemark: location.placemark)
//        dismissKeyboard()
//        delegate?.receivedLocationInformation(self, coordinate: coord, address: address, name: name)
//    }

}

extension NewTagLocationController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        
        let identifier = "locationAnnotationIdentifier"
        var view: MKPinAnnotationView!
        if let v = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView{
            view = v
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        view.canShowCallout = true
        
        let addButton = UIButton(type: UIButtonType.RoundedRect)
        addButton.setTitle("Add Location", forState: .Normal)
        addButton.sizeToFit()
        view.rightCalloutAccessoryView = addButton
        
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation as? LocationAnnotation else {
            return
        }
        
        let coord = annotation.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        
        for (i, location) in self.locationsFound.enumerate() {
            if (location.placemark.coordinate.latitude == coord.latitude &&  location.placemark.coordinate.longitude == coord.longitude) {
                selectedIndexPath = NSIndexPath(forRow: i, inSection: 0)
                tableView.selectRowAtIndexPath(selectedIndexPath, animated: true, scrollPosition: .Top)
//                tableView.delegate!.tableView!(tableView, didSelectRowAtIndexPath: selectedIndexPath!)

            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("tapped accessory")
        if let annotation = view.annotation as? LocationAnnotation {
            let coord = annotation.coordinate
            let placemark = annotation.placemark
            let name = getName(fromPlacemark: placemark)
            let address = getAddress(fromPlacemark: placemark)
            dismissKeyboard()
            delegate?.receivedLocationInformation(self, coordinate: coord, address: address, name: name)
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if !hasReceivedUserLocation {
            let coord = mapView.userLocation.coordinate
            let region = MKCoordinateRegionMakeWithDistance(coord, unzoomWidth, unzoomWidth)
            mapView.setRegion(region, animated: true)
            hasReceivedUserLocation = true
        }
    }
}

