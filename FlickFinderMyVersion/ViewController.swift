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
    
    let api = FlickrAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        beginKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        terminateKeyboardNotifications()
    }
    
    @IBAction func phraseSearchButtonPressed(_ sender: UIButton) {
        
        if !(phraseTextField.text?.isEmpty)! {
            api.searchForFlick(phrase: phraseTextField.text!, bbox: nil) {
                (error, images) in
                
                if error == nil {
                    print("data task completed successfully")
                    let dict = images?.last
                    for (key, value) in  dict! {
                        
                        //dispatch
                        DispatchQueue.main.async {
                            self.flickTitleLabel.text = key
                            self.flickImageView.image = value
                        }
                    }
                }
                else {
                    print("error during data task")
                }
            }
        }
    }
    
    @IBAction func geoSearchButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func locationsButtonPressed(_ sender: UIButton) {
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "LocationsViewController") as! LocationsViewController
        let nc = UINavigationController(rootViewController: controller)
        present(nc, animated: true, completion: nil)
    }
}

// handle keyboard shift and notifications for keyboard
extension ViewController {
    
    func beginKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    func terminateKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillShow,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillHide,
                                                  object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if self.view.superview?.frame.origin.y == 0.0 {
            self.view.superview?.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        
        if (self.view.superview?.frame.origin.y)! < 0.0 {
            self.view.superview?.frame.origin.y -= (self.view.superview?.frame.origin.y)!
        }
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let frame = userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return frame.cgRectValue.size.height / 1.5
    }
}

// handle textField delegate functions
extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
