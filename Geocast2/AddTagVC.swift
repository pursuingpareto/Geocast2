//
//  AddTagController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class AddTagViewController : UITableViewController {
    private var locations = [MKMapItem]()
    private var searchController = UISearchController()
    var episode: Episode!
    
    private var nameForLocation: String?
    private var addressForLocation: String?
    private var descriptionForTag: String?
    private var locationToAdd: CLLocation?
    private let locationManager = CLLocationManager()
    private var locationRadius: CLLocationDistance?
    
    private let searchLocationCellIdentifier = "searchLocationCell"
    private let locationCellIdentifier = "locationCell"
    private let tagDescriptionCellIdentifier = "tagDescriptionCell"
    private let addTagCellIdentifier = "addTagCell"
    private let tagLocationButtonsCellIdentifier = "tagLocationButtonsCell"
    
    var tagManager = TagManager.sharedInstance
    
    private let defaultLocation = CLLocation(latitude: 37.7833, longitude: -122.4167)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupBackButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        } else {
            if searchController.active {
                print("telling tableview that there are \(locations.count) locations")
                return locations.count
            } else {
                return 1 // 1 for the TagDescriptionCell
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("addTagCell", forIndexPath: indexPath) as! AddTagCell
                cell.episodeLabel.text = "\(episode.podcast.title) - \(episode.title)"
                print(nameForLocation)
                if nameForLocation == nil {
                    print("NAME FOR LOCATION IS NILL")
                    cell.locationLabel.text = "Must add location"
                    cell.locationLabel.textColor = UIColor.lightGrayColor()
                } else {
                    print("name for location is NOT nil")
                    cell.locationLabel.text = nameForLocation!
                    cell.locationLabel.textColor = UIColor.blackColor()
                }
                if descriptionForTag == nil {
                    cell.descriptionLabel.text = "Must add description"
                    cell.descriptionLabel.textColor = UIColor.lightGrayColor()
                } else {
                    cell.descriptionLabel.text = descriptionForTag!
                    cell.descriptionLabel.textColor = UIColor.blackColor()
                }                
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("tagLocationButtonsCell", forIndexPath: indexPath) as! TagLocationButtonsCell
                // TODO : Wire up the button so it actually adds a tag.
                
                if nameForLocation != nil && descriptionForTag != nil && locationToAdd != nil {
                    cell.addTagButton.enabled = true
                } else {
                    cell.addTagButton.enabled = false
                }
                
                return cell
            }
        }
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("searchLocationCell", forIndexPath: indexPath) as! SearchLocationCell
            cell.searchBar = searchController.searchBar
            if nameForLocation != nil {
                //                cell.searchBar.text = nameForLocation
            }
            return cell
        } else  {
            if searchController.active {
                let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath) as! LocationCell
                print("indexPath is \(indexPath)")
                print("locations has count \(locations.count)")
                let location = locations[indexPath.row]
                let pm = location.placemark
                
                // get address
                let address = getAddress(fromPlacemark: pm)
                cell.addressLabel.text = address
                
                cell.nameLabel.text = getName(fromPlacemark: pm)
                return cell
                
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("tagDescriptionCell", forIndexPath: indexPath) as! TagDescriptionCell
                cell.textView.text = descriptionForTag
                cell.textView.delegate = self
                return cell
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Tag"
        } else if section == 1 {
            return "Add Location"
        } else {
            if searchController.active {
                return nil
            } else {
                return "Add Description"
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchController.active && indexPath.section == 2 {
            let location = locations[indexPath.row]
            nameForLocation = getName(fromPlacemark: location.placemark)
            locationToAdd = location.placemark.location
            locationRadius = location.placemark.location?.horizontalAccuracy
            print("nameForLocation is \(nameForLocation)")
            addressForLocation = getAddress(fromPlacemark: location.placemark)
            print("addressForLocation is \(addressForLocation)")
            searchController.active = false
            searchController.searchBar.resignFirstResponder()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return 100
            } else {
                return 44
            }
        }
        if indexPath.section == 1 {
            return 44
        } else {
            if searchController.active {
                return 66
            } else {
                return 88
            }
        }
    }
    
    func getAddress(fromPlacemark pm: MKPlacemark) -> String {
        var address: String = ""
        if let addressLines = pm.addressDictionary!["FormattedAddressLines"] as? [String]{
            for line in addressLines {
                address += "\(line) "
            }
            return address
        } else {
            return (pm.name != nil) ? pm.name! : ""
        }
    }
    
    private func setupSearchController() {
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.searchBar.sizeToFit()
            controller.searchBar.placeholder = "Search for location or address"
            controller.dimsBackgroundDuringPresentation = false
            let cell = self.tableView.dequeueReusableCellWithIdentifier("searchLocationCell", forIndexPath: NSIndexPath(forRow: 0, inSection: 1)) as! SearchLocationCell
            controller.searchBar.bounds = cell.bounds
            controller.searchBar.searchBarStyle = UISearchBarStyle.Minimal
            cell.searchBar = controller.searchBar
            cell.addSubview(cell.searchBar)
            return controller
        })()
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.delegate = self
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .System)
        backButton.setTitle("Back", forState: .Normal)
        backButton.sizeToFit()
        backButton.bounds.size.height = 70
        //        backButton.frame.origin = CGPointMake(10, 10)
        backButton.contentHorizontalAlignment = .Left
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0)
        backButton.addTarget(self, action: "dismiss", forControlEvents: .TouchUpInside)
        tableView.tableHeaderView = backButton
    }
    
    private func getName(fromPlacemark pm: MKPlacemark) -> String? {
        var text: String? = pm.name
        if let areaOfInterest = pm.areasOfInterest?.first {
            text = areaOfInterest
        }
        return text
    }
    
    private func search(string: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchController.searchBar.text
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let location : CLLocation!
        if let loc = locationManager.location {
            location = loc
        } else {
            location = defaultLocation
        }
        request.region = MKCoordinateRegion(center: location.coordinate, span:span)
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler({
            (response: MKLocalSearchResponse?, error: NSError?) in
            guard error == nil else {
                print(error)
                return
            }
            guard let response = response else {
                return
            }
            self.locations = response.mapItems
            self.tableView.reloadData()
        })
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addTagButtonPressed(sender: AnyObject) {
        let message = "This will tag \(episode.podcast.title): \(episode.title) with the location \(nameForLocation!)"
        let alertController = UIAlertController(title: "Confirm Location Tag", message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert) in
        })
        alertController.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "Add tag", style: .Default, handler: {
            (alert) in
            self.tagManager.addTag(forEpisode: self.episode, atLocation: self.locationToAdd!, withName: self.nameForLocation!, withDescription: self.descriptionForTag!, withAddress: self.addressForLocation!, withRadius: self.locationRadius!)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: {})
    }
}

extension AddTagViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        locations.removeAll(keepCapacity: false)
        if let text = searchController.searchBar.text {
            search(text)
        }
    }
}

extension AddTagViewController: UISearchControllerDelegate {
    func didPresentSearchController(searchController: UISearchController) {
        searchController.active = true
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        searchController.active = false
    }
}

extension AddTagViewController: UITextViewDelegate {
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            descriptionForTag = textView.text
            textView.resignFirstResponder()
            tableView.reloadData()
            return false
        } else {
            return true
        }
    }
}