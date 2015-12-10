//
//  NewTagLocationController.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/10/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class NewTagLocationController: UIViewController {
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    private var searchController = UISearchController()
    private var locationsFound = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = false
        searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.searchBar.sizeToFit()
            controller.searchBar.placeholder = "Search for location or address"
            controller.hidesNavigationBarDuringPresentation = false
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.frame = self.searchBar.frame
            

            

            
            controller.searchBar.sizeToFit()
            
            print("controller's searchBar is \(controller.searchBar)")
            return controller
        })()
        searchBar.delegate = self
        searchController.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        mapView.delegate = self
        print("New Tag Location viewDidLoad")
    }
    
    func updateViewWithNewLocations() {
        dispatch_async(dispatch_get_main_queue(), {
          self.tableView.reloadData()
        })
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
        request.naturalLanguageQuery = searchController.searchBar.text
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
            
            self.locationsFound = response.mapItems
            self.updateViewWithNewLocations()
        })
    }
}

extension NewTagLocationController: UISearchControllerDelegate {
    func didPresentSearchController(searchController: UISearchController) {
        searchController.active = true
        self.navigationController?.navigationBar.translucent = true
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        searchController.active = false
        self.navigationController?.navigationBar.translucent = false
    }
    
    func presentSearchController(searchController: UISearchController) {
        // TODO: ...nothing?
    }
}

extension NewTagLocationController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.navigationController?.navigationBarHidden = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.navigationController?.navigationBarHidden = false
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
        print("indexPath is \(indexPath)")
        print("locations has count \(locationsFound.count)")
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
    
}

extension NewTagLocationController: MKMapViewDelegate {
    
}

extension NewTagLocationController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        print("called updateSearchResultsForSearchController")
        locationsFound.removeAll(keepCapacity: false)
        if let text = searchController.searchBar.text {
            search(forString: text)
        }
    }
}
