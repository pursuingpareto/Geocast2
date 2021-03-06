//
//  NewTagController.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/10/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit
import MapKit

class NewTagController: UITableViewController {
    
    var episode: Episode!
    var coordinate: CLLocationCoordinate2D?
    var potentialName: String? = nil
    var nameForLocation: String? = nil
    var addressForLocation: String? = nil
    var descriptionForTag: String? = nil
    
    private let maxCharactersForLocationName = 50
    private let maxCharactersForDescription = 150
    private let minCharactersForLocationName = 4
    
    private var completedCellColor = UIColor(red: 169/255, green: 255/255, blue: 142/255, alpha: 0.35)
    private let incompleteCellColor = UIColor(red: 246/255, green: 236/255, blue: 5/255, alpha: 0.14)
    
    private var tagManager = TagManager.sharedInstance
    private var defaultRadius: CLLocationDistance = 0
    
    @IBOutlet weak var introTextView: UITextView!
    
    
    @IBOutlet weak var introTextLabel: UILabel!
    @IBOutlet weak var addLocationCell: UITableViewCell!
    @IBOutlet weak var addLocationLabel: UILabel!
    
    @IBOutlet weak var nameLocationCell: UITableViewCell!
    @IBOutlet weak var nameLocationLabel: UILabel!
    @IBOutlet weak var nameLocationTextField: UITextField!
    
    @IBOutlet weak var addDescriptionCell: UITableViewCell!
    @IBOutlet weak var addDescriptionLabel: UILabel!
    @IBOutlet weak var addDescriptionTextView: UITextView!
    
    
    @IBOutlet weak var addTagButton: UIButton!
    
    @IBAction func addTagPressed(sender: UIButton) {
        let message = "This will tag \(episode.podcast.title): \(episode.title) with the location \(nameForLocation!)"
        let alertController = UIAlertController(title: "Confirm Location Tag", message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert) in
        })
        alertController.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "Add tag", style: .Default, handler: {
            (alert) in
            let locationToAdd = CLLocation(latitude: (self.coordinate?.latitude)!, longitude: (self.coordinate?.longitude)!)
            self.tagManager.addTag(forEpisode: self.episode, atLocation: locationToAdd, withName: self.nameForLocation!, withDescription: self.descriptionForTag, withAddress: self.addressForLocation!, withRadius: self.defaultRadius)
            self.showThanksForAddingTag()
        })
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: {})
    }
    
    private func showThanksForAddingTag() {
        let alertController = UIAlertController(title: "Thanks for Contributing to the Geocast Community!", message: "Your tag was added. Please help grow the Geocast community by reviewing us on the App Store.", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Not Now", style: .Cancel, handler: {
            (alert) in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        alertController.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "Review Geocast", style: .Default, handler: {
            (alert) in
            let appID = 1071564861
            let appStoreUrl = NSURL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(appID)&onlyLatestVersion=true&pageNumber=0&sortOrdering=1)")!
            UIApplication.sharedApplication().openURL(appStoreUrl)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: {
//            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLocationTextField.delegate = self
        addDescriptionTextView.delegate = self
        nameLocationTextField.hidden = true
        addDescriptionTextView.hidden = true
        addTagButton.enabled = false
        addDescriptionTextView.layer.borderColor = UIColor.grayColor().colorWithAlphaComponent(0.5).CGColor
        addDescriptionTextView.layer.borderWidth = 0.5
        addDescriptionTextView.layer.cornerRadius = 5
        addDescriptionTextView.clipsToBounds = true
        let back = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain , target: self, action: "backButtonPressed:")
        navigationItem.setLeftBarButtonItem(back, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setupViewForEpisode()
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("View will disappear!")
        super.viewWillDisappear(animated)
        if let tabVC = self.tabBarController as? MainTabController {
            print("Changing selected tabIndex")
            tabVC.selectedIndex = MainTabController.TabIndex.playerIndex.rawValue
        } else {
            print("NOT changing selected tag index")
        }
    }
    
    func backButtonPressed(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func setupViewForEpisode() {
        introTextLabel.text = "Four steps to make your contribution"
        addLocationCell.backgroundColor = (coordinate == nil) ? incompleteCellColor : completedCellColor
        nameLocationCell.backgroundColor = (nameForLocation == nil) ? incompleteCellColor : completedCellColor
        addDescriptionCell.backgroundColor = (descriptionForTag == nil) ? incompleteCellColor : completedCellColor
        
        self.title = "Add Tag for \(episode.title)"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addLocationSegue" {
            let destinationVC = segue.destinationViewController as! NewTagLocationController
            destinationVC.delegate = self
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let identifier = cell?.reuseIdentifier {
            switch identifier {
            case "listen":
                return
            case "add":
                break
            case "name":
                if nameForLocation == nil {
                    if potentialName != nil {
                        nameLocationTextField.text = potentialName
                        nameLocationTextField.selectAll(nil)
                    }
                }
                nameLocationTextField.hidden = false
                dispatch_async(dispatch_get_main_queue(), {
                    self.nameLocationTextField.becomeFirstResponder()
                    self.tableView.beginUpdates()
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    self.tableView.endUpdates()
                })
            case "description":
                addDescriptionTextView.hidden = false
                dispatch_async(dispatch_get_main_queue(), {
                    self.addDescriptionTextView.becomeFirstResponder()
                    self.tableView.beginUpdates()
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    self.tableView.endUpdates()
                })
            default:
                break
            }
        }
//        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            return false
        } else if indexPath.section == 0 {
            return false
        } else {
            return true
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 70
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return 60
            case 2:
                return nameLocationTextField.hidden ? 60 : 100
            case 3:
                return addDescriptionTextView.hidden ? 60 : 150
            default:
                return 60
            }
        } else {
            return 90
        }
    }
    
    private func updateAddTagButton() {
        guard coordinate != nil else {
            addTagButton.enabled = false
            return
        }
//        guard descriptionForTag != nil else {
//            addTagButton.enabled = false
//            return
//        }
        guard nameForLocation != nil else {
            addTagButton.enabled = false
            return
        }
        addTagButton.enabled = true
    }
}

extension NewTagController: LocationInformationUpdating {
    func receivedLocationInformation(fromViewController: UIViewController, coordinate: CLLocationCoordinate2D, address: String?, name: String?) {
        self.coordinate = coordinate
        self.potentialName = name
        self.addressForLocation = address
        addLocationCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        addLocationCell.backgroundColor = completedCellColor
        updateAddTagButton()
        navigationController?.popToRootViewControllerAnimated(true)
    }
}

extension NewTagController: UITextViewDelegate {
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView == addDescriptionTextView {
            if text == "\n" {
                self.descriptionForTag = textView.text
                textView.resignFirstResponder()
                addDescriptionCell.backgroundColor = completedCellColor
                addDescriptionCell.accessoryType = UITableViewCellAccessoryType.Checkmark
                updateAddTagButton()
                return false
            }
            
            guard let prevText = textView.text else { return true }
            let newLength = prevText.characters.count + text.characters.count - range.length
            return newLength <= maxCharactersForDescription
            
        }
        
        
        return true
        
    }
}

extension NewTagController: UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == nameLocationTextField {
            if string == "\n" {
                
                if textField.text?.characters.count < minCharactersForLocationName {
                    let message = "Location names must have at least \(minCharactersForLocationName) characters."
                    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)

                    let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: {
                        (alert) in
//                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    alertController.addAction(confirmAction)
                    self.presentViewController(alertController, animated: true, completion: {})
                } else {
                    self.nameForLocation = textField.text
                    textField.resignFirstResponder()
                    nameLocationCell.backgroundColor = completedCellColor
                    nameLocationCell.accessoryType = UITableViewCellAccessoryType.Checkmark
                    updateAddTagButton()
                    return false
                }
            }
            
            guard let prevText = textField.text else { return true }
            let newLength = prevText.characters.count + string.characters.count - range.length
            return newLength <= maxCharactersForLocationName
        }
        return true
    }
}
