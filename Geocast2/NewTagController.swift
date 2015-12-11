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
    var potentialName: String?
    var nameForLocation: String?
    var addressForLocation: String?
    var descriptionForTag: String?
    
    private var completedCellColor = UIColor(red: 169/255, green: 255/255, blue: 142/255, alpha: 0.35)
    
    
    @IBOutlet weak var introTextView: UITextView!
    
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupViewForEpisode()
    }
    
    func setupViewForEpisode() {
        
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
        print("cell is \(cell) with identifier \(cell?.reuseIdentifier)")
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
        guard descriptionForTag != nil else {
            addTagButton.enabled = false
            return
        }
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
        }
        return true
        
    }
}

extension NewTagController: UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == nameLocationTextField {
            if string == "\n" {
                self.nameForLocation = textField.text
                textField.resignFirstResponder()
                nameLocationCell.backgroundColor = completedCellColor
                nameLocationCell.accessoryType = UITableViewCellAccessoryType.Checkmark
                updateAddTagButton()
                return false
            }
        }
        return true
    }
}
