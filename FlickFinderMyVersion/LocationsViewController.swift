//
//  LocationsViewController.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

import UIKit
import MapKit

class LocationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Flick Locations"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissVC))
    }
    
    func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
}
