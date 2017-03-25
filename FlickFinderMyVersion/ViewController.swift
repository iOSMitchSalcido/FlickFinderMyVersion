//
//  ViewController.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //@IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var flickTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var locationsButton: UIButton!
    @IBOutlet weak var geoSearchButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    
    var imageViewArray = [UIImageView]()
    var flickScrollView: UIScrollView!
    var activityIndicator: UIActivityIndicatorView!

    var defaultImageView: UIImageView!
    
    let api = FlickrAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDid")

        flickScrollView = UIScrollView(frame: backgroundView.bounds)
        backgroundView.addSubview(flickScrollView)

        activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame.size = CGSize(width: 20, height: 20)
        //backgroundView.addSubview(activityIndicator)

        let iv = UIImageView(frame: flickScrollView.bounds)
        iv.image = UIImage(named: "DefaultImage")
        iv.contentMode = .scaleAspectFit
        imageViewArray.append(iv)
        flickScrollView.addSubview(iv)
        
        let iv2 = UIImageView(frame: flickScrollView.bounds)
        iv2.image = UIImage(named: "DefaultImage")
        iv2.contentMode = .scaleAspectFit
        imageViewArray.append(iv2)
        flickScrollView.addSubview(iv2)
    }
    
    override func viewWillLayoutSubviews() {
        print("willLayout...")
        
        flickScrollView.frame = backgroundView.bounds
        print("bgv bounds: \(backgroundView.bounds)")
        print("sv bounds: \(flickScrollView.bounds)")
        print("sv bounds: \(flickScrollView.frame)")
        var frame = flickScrollView.bounds
        frame.origin = CGPoint(x: 0, y: 0)
        var size = CGSize(width: 0, height: frame.size.height)
        for imageView in imageViewArray {
            imageView.frame = frame
            print("IV Frame: \(frame)")
            frame.origin.x += frame.size.width
            size.width += frame.size.width
        }
        
        flickScrollView.contentSize = size
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        beginKeyboardNotifications()
        activityIndicator.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        terminateKeyboardNotifications()
    }
    
    @IBAction func phraseSearchButtonPressed(_ sender: UIButton) {
        
        if !(phraseTextField.text?.isEmpty)! {
            
            enableUIState(false)
            
            flickScrollView.alpha = 0.5
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            api.searchForFlick(phrase: phraseTextField.text!, bbox: nil) {
                (error, images) in
                
                if let error = error {
                    
                    var alertTitle = "Unknown error"
                    var alertMessage = ""
                    switch error {
                    case .searchItems(let value):
                        alertTitle = "Search Items Error"
                        alertMessage = value
                        break
                    case .dataTask(let value):
                        alertTitle = "Network error"
                        alertMessage = value
                        break
                    }
                    
                    let alert = UIAlertController(title: alertTitle,
                                                  message: alertMessage,
                                                  preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK",
                                               style: .cancel,
                                               handler: nil)
                    
                    alert.addAction(action)
                    
                    DispatchQueue.main.async {
                        self.present(alert,
                                     animated: true,
                                     completion: nil)
                    }
                }
                else {
                    
                    let dict = images?.last
                    for (key, _) in  dict! {
                        
                        //dispatch
                        DispatchQueue.main.async {
                            self.flickTitleLabel.text = key
                        }
                    }
                }
                
                //dispatch
                DispatchQueue.main.async {
                    self.enableUIState(true)
                    self.flickScrollView.alpha = 1.0
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
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

extension ViewController {
    
    func enableUIState(_ enable: Bool) {
        self.phraseSearchButton.isEnabled = enable
        self.geoSearchButton.isEnabled = enable
        self.locationsButton.isEnabled = enable
    }
}
