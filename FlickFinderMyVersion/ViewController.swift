//
//  ViewController.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var flickTitleLabel: UILabel!
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var locationsButton: UIButton!
    @IBOutlet weak var geoSearchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func phraseSearchButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func geoSearchButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func locationsButtonPressed(_ sender: UIButton) {
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "LocationsViewController") as! LocationsViewController
        let nc = UINavigationController(rootViewController: controller)
        present(nc, animated: true, completion: nil)
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
