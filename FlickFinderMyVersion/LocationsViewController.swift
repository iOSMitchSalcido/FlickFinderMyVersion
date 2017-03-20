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

    let locations = ["San Francisco", "Chico, CA", "Los Angeles", "Moscow", "London", "Tokyo"]
    
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

extension LocationsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Popular Locations"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationsCellID")!
        cell.textLabel?.text = locations[indexPath.row]
        return cell
    }
}

extension LocationsViewController: UITextFieldDelegate {
    
}
