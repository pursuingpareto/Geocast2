//
//  NewTagController.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/10/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class NewTagController: UITableViewController {
    
    var episode: Episode!
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setupViewForEpisode()
    }
    
    func setupViewForEpisode() {
        
    }
    
    
}
