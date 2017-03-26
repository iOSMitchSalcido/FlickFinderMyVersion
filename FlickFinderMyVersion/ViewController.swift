//
//  ViewController.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
About ViewController.swift:
 Presents a scrollView for showing found flicks, phrase search textField, and geo search textFields.
 Handles creating Flickr searches using either a phrase or a geo search.
 */

import UIKit

class ViewController: UIViewController {

    // +/- resolution in degrees of geo search..used to create bbox
    let GEO_RESOLUTION: Float = 0.5
    
    //@IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var flickTitleLabel: UILabel!            // show flick title
    @IBOutlet weak var phraseTextField: UITextField!        // search for Flick by text phrase
    @IBOutlet weak var longitudeTextField: UITextField!     // lon: Geo flick search text
    @IBOutlet weak var latitudeTextField: UITextField!      // lat: Geo flick search text
    @IBOutlet weak var phraseSearchButton: UIButton!        // invoke search by text phrase
    @IBOutlet weak var locationsButton: UIButton!           //TODO: !! WORK IN PROGRESS !!
    @IBOutlet weak var geoSearchButton: UIButton!           // invoke search by geo
    
    // container for flickScrollView and activityView
    @IBOutlet weak var backgroundView: UIView!
    
    // viewer for flicks in scrolling format
    // adding programmatically..need to review autoLayout
    // ...don't like doing this way. When I add sv in storyBoard, views in sc seem
    // to be shifted down by ~navBar and statusbar heights...
    var flickScrollView: UIScrollView!

    // store imageView's that are in flickScrollView
    var imageViewArray = [UIImageView]()
    
    // animate when searching....
    var activityIndicator: UIActivityIndicatorView!

    // when no images are available
    var defaultImageView: UIImageView!
    
    // ref to API
    let api = FlickrAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create/config flickScrollView.. add to backgroundView
        flickScrollView = UIScrollView(frame: backgroundView.bounds)
        flickScrollView.isPagingEnabled = true
        backgroundView.addSubview(flickScrollView)
        
        // create activityView..add to backgroundView
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame.origin.x = backgroundView.bounds.size.width / 2.0 - activityIndicator.frame.width / 2.0
        activityIndicator.frame.origin.y = backgroundView.bounds.size.height / 2.0 - activityIndicator.frame.height / 2.0
        backgroundView.addSubview(activityIndicator)

        // default image.. shown when no Flicks
        defaultImageView = UIImageView()
        defaultImageView.image = UIImage(named: "DefaultImage")
        imageViewArray.append(defaultImageView)
        flickScrollView.addSubview(defaultImageView)
        
        // layout flickScrollView
        updateScrollView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // begin notifications...hide activityIndicator
        beginKeyboardNotifications()
        activityIndicator.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // end notifications
        terminateKeyboardNotifications()
    }
    
    // phrase search
    @IBAction func searchButtonPressed(_ sender: UIButton) {
        
        /*
         Invoke a Flickr image search by phrase, using text in textField
         */
        
        // set enabled state of UI, buttons, etc
        enableUIState(false)
        
        // dim sv, show activityView animated
        flickScrollView.alpha = 0.5
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        var phrase: String? = nil
        var bbox: String? = nil
        if sender == phraseSearchButton {
            phrase = searchPhase()
        }
        else if sender == geoSearchButton {
            bbox = searchGeo()
        }
        
        // api call
        api.searchForFlick(phrase: phrase, bbox: bbox) {
            (error, images) in
            
            // completion
            
            if let error = error {
                
                /*
                 Error occurred.
                 Use error info to create an alert to present to user
                 */
                
                // default title, message
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
                
                // create alert, action
                let alert = UIAlertController(title: alertTitle,
                                              message: alertMessage,
                                              preferredStyle: .alert)
                let action = UIAlertAction(title: "OK",
                                           style: .cancel,
                                           handler: nil)
                
                alert.addAction(action)
                
                // present alert
                DispatchQueue.main.async {
                    self.present(alert,
                                 animated: true,
                                 completion: nil)
                }
            }
            else {
                
                // no error..continue with presenting flickr image
                
                // get dictionary from images dictionary
                let dict = images?.last
                for (key, value) in  dict! {
                    
                    // create imageView to place new image in
                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = value
                    
                    // append new imageView to array
                    self.imageViewArray.append(imageView)
                    
                    //dispatch
                    DispatchQueue.main.async {
                        
                        // update titleLabel, imageViews in sv
                        self.flickTitleLabel.text = key
                        self.updateScrollView()
                    }
                }
            }
            
            //dispatch
            DispatchQueue.main.async {
                
                // return UI to ready state
                self.enableUIState(true)
                self.flickScrollView.alpha = 1.0
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        }
    }
    
    // invoke LocationsVC ...work in progress
    @IBAction func locationsButtonPressed(_ sender: UIButton) {
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "LocationsViewController") as! LocationsViewController
        let nc = UINavigationController(rootViewController: controller)
        present(nc, animated: true, completion: nil)
    }
}

// handle keyboard shift and notifications for keyboard
extension ViewController {
    
    // begin notifications for keyboard showing/hiding
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
    
    // end notifications for keyboard showing/hiding
    func terminateKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillShow,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillHide,
                                                  object: nil)
    }
    
    // action method for keyboardWillShow notification
    func keyboardWillShow(_ notification: Notification) {
        
        // shift view to keep textFields visible while editing
        if self.view.superview?.frame.origin.y == 0.0 {
            self.view.superview?.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    // action method for keyboardWillHide notification
    func keyboardWillHide(_ notification: Notification) {
        
        // return view to normal y origin
        if (self.view.superview?.frame.origin.y)! < 0.0 {
            self.view.superview?.frame.origin.y -= (self.view.superview?.frame.origin.y)!
        }
    }
    
    // return keyboard height..less some aesthetic scaling...
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

// misc helper functions
extension ViewController {
    
    // set enable state of UI
    func enableUIState(_ enable: Bool) {
        self.phraseSearchButton.isEnabled = enable
        self.geoSearchButton.isEnabled = enable
        self.locationsButton.isEnabled = enable
    }
    
    // helper method to layout views in flickScrollView
    func updateScrollView() {
        
        // test imageViews in array... Add to flickScrollView if not currently in it's superView
        // ...imageView is added to array in closure for flick search..see function below
        for imageView in imageViewArray {
            if imageView.superview == nil {
                flickScrollView.addSubview(imageView)
            }
        }
        
        // test if a flick is present...remove defaultImage
        if imageViewArray.count == 2 && imageViewArray.first == defaultImageView {
            let iv = imageViewArray.removeFirst()
            iv.removeFromSuperview()
        }
        
        // layout frames in flickScrollView
        flickScrollView.frame = backgroundView.bounds
        var frame = flickScrollView.bounds
        frame.origin = CGPoint(x: 0, y: 0)
        var size = CGSize(width: 0, height: frame.size.height)
        for imageView in imageViewArray {
            imageView.frame = frame
            frame.origin.x += frame.size.width
            size.width += frame.size.width
        }
        flickScrollView.contentSize = size
        
        // scroll to last added imageView
        frame.origin.x -= frame.size.width
        flickScrollView.scrollRectToVisible(frame, animated: true)
    }
    
    // helper function, return search text from phrase text field
    func searchPhase() -> String? {
        
        // verify not empty text
        if !(phraseTextField.text?.isEmpty)! {
            
            // verify characters other than " "
            let characters = phraseTextField.text?.characters
            for character in characters! {
                if character != " " {
                    return phraseTextField.text
                }
            }
        }
        
        return nil
    }
    
    // helper function, return bbox in string from lon/lat textFields
    func searchGeo() -> String? {
        
        // function to test is a float falls on/between min/max
        func withinRange(_ value: Float, min: Float, max: Float) -> Bool {
            if value >= min && value <= max {
                return true
            }
            return false
        }
        
        // verify valid floats in textFields
        guard let lat = Float(latitudeTextField.text!),
        let lon = Float(longitudeTextField.text!) else {
            return nil
        }
    
        // create min/max geo values
        let lonMin = lon - GEO_RESOLUTION / 2.0
        let lonMax = lonMin + GEO_RESOLUTION
        let latMin = lat - GEO_RESOLUTION / 2.0
        let latMax = latMin + GEO_RESOLUTION
        
        // verify each within range
        if !withinRange(lonMin, min: -180.0, max: 180.0) {
            return nil
        }
        
        if !withinRange(lonMax, min: -180.0, max: 180.0) {
            return nil
        }
        
        if !withinRange(latMin, min: -90.0, max: 90.0) {
            return nil
        }
        
        if !withinRange(latMax, min: -90.0, max: 90.0) {
            return nil
        }
        
        // convert to string, return
        return "\(lonMin),\(latMin),\(lonMax),\(latMax)"
    }
}
