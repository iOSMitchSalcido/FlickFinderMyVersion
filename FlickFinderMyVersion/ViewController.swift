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
    
    // trash to delete flick
    var trashBbi: UIBarButtonItem!
    
    // container for flickScrollView and activityView
    @IBOutlet weak var backgroundView: UIView!
    
    // viewer for flicks in scrolling format
    // adding programmatically..need to review autoLayout
    // ...don't like doing this way. When I add sv in storyBoard, views in sc seem
    // to be shifted down by ~navBar and statusbar heights...
    var flickScrollView: UIScrollView!
    
    // maintain flicks in flicksScrollView as tuple, title and imageView
    var flicksArray = [(String, UIImageView)]()
    
    // animate when searching....
    var activityIndicator: UIActivityIndicatorView!

    // when no images are available
    var defaultTitle = "Search For Flicks !"
    
    // ref to API
    let api = FlickrAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // trashBbi on left navbar
        trashBbi = UIBarButtonItem(barButtonSystemItem: .trash,
                                   target: self,
                                   action: #selector(trashBbiPressed(_:)))
        trashBbi.isEnabled = false
        navigationItem.leftBarButtonItem = trashBbi
        
        // create/config flickScrollView.. add to backgroundView
        flickScrollView = UIScrollView(frame: backgroundView.bounds)
        flickScrollView.isPagingEnabled = true
        flickScrollView.delegate = self
        backgroundView.addSubview(flickScrollView)
        
        // create activityView..add to backgroundView
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame.origin.x = backgroundView.bounds.size.width / 2.0 - activityIndicator.frame.width / 2.0
        activityIndicator.frame.origin.y = backgroundView.bounds.size.height / 2.0 - activityIndicator.frame.height / 2.0
        backgroundView.addSubview(activityIndicator)

        // initial load default image
        addFlick(nil)        
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
                    
                    //dispatch
                    DispatchQueue.main.async {
                        // update flick sv
                        self.addFlick((key, value))
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
    
    func trashBbiPressed(_ sender: UIBarButtonItem) {
        removeFlickAt(index: indexOfVisibleFlick())
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

// flickScrollView functions
extension ViewController {

    // function to return the index of the visible view in sv
    func indexOfVisibleFlick() -> Int {
        
        // determine index of visible imageView in sv
        let xOffset = flickScrollView.contentOffset.x
        let width = flickScrollView.frame.size.width
        let index = Int(xOffset / width)
        
        // default flick is at location 0. If more that one flick then
        // want non-default flick
        if flicksArray.count > 1 {
            return index + 1
        }
        return index
    }
    
    // function to add a new flick to scrollView
    func addFlick(_ flick: (String, UIImage)?) {
        
        // Add flick to scrollView. If nil tuple, then insert default flick/title
        var flickTitle: String!
        var flickImage: UIImage!
        if let flick = flick {
            flickTitle = flick.0
            flickImage = flick.1
        }
        else {
            flickTitle = defaultTitle
            flickImage = UIImage(named: "DefaultImage")
        }

        // append flicksArray, add to flickScrollView
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = flickImage
        flicksArray.append((flickTitle, imageView))
        flickScrollView.addSubview(imageView)
        
        // flickTitle
        flickTitleLabel.text = flickTitle
        
        // trash
        trashBbi.isEnabled = flicksArray.count > 1
        
        // layout frames in flickScrollView
        layoutFlickScrollView()
        
        // scroll to last added imageView
        flickScrollView.scrollRectToVisible(imageView.frame, animated: true)
    }
    
    // function to delete a flick
    func removeFlickAt(index: Int) {
        
        // get flick
        let flick = flicksArray[index]
        
        // dim flickTitle for aesthetics while deleting
        flickTitleLabel.alpha = 0.3
        
        // disable scrollView while deletion is happening
        flickScrollView.isUserInteractionEnabled = false
        
        // disbale trashBbi until this operation is complete
        trashBbi.isEnabled = false
        
        // test for flick count
        if flicksArray.count > 2 {
            
            // deletion for > 1 flick...default flick is not counted !!
            
            // get targetflick ImageView...the flick to scroll to after flick deletion
            var targetFlick: (String, UIImageView)!
            if index == (flicksArray.count - 1) {
                targetFlick = flicksArray[index - 1]
            }
            else {
                targetFlick = flicksArray[index + 1]
            }
            
            // scroll to next flick, targetFlick prior to deletion..aesthetics
            self.flickScrollView.scrollRectToVisible(targetFlick.1.frame, animated: true)
            
            // after scrolling to next flick, handle actual flick deletion
            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) {
                _ in
                
                // remove flick from array and scrollView...re-layout scrollView
                self.flicksArray.remove(at: index)
                flick.1.removeFromSuperview()
                self.layoutFlickScrollView(scrollToFlick: targetFlick)
                
                // done with deletion...re-enable user interaction
                self.flickScrollView.isUserInteractionEnabled = true
                self.flickTitleLabel.alpha = 1.0
                self.trashBbi.isEnabled = true
            }
        }
        else {
            
            // deletion for last flick in array...default flick not counted !!
            
            // dim imageView
            UIView.animate(withDuration: 0.2) {
                flick.1.alpha = 0.0
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.21, repeats: false) {
                _ in
                
                // remove flick from array and scrollView...re-layout scrollView
                self.flicksArray.remove(at: index)
                flick.1.removeFromSuperview()
                self.layoutFlickScrollView()

                // done with deletion...re-enable user interaction
                self.flickScrollView.isUserInteractionEnabled = true
                self.flickTitleLabel.alpha = 1.0
            }
        }
    }
    
    // helper function..layout subviews
    // landingImageView is an optional to indicate which view to scroll to
    // upon completion of layout
    func layoutFlickScrollView(scrollToFlick: (String, UIImageView)? = nil) {
        
        /*
         Default flick is at location 0
         If more than one flick, the first flick is placed
         on top of default flick, and the default flick is
         set to hidden
        */
        
        // get default image, create startIndex for iteration
        let flicks = flicksArray[0]
        var startIndex = 0
        
        // test for > 1 flick (there is default image and one or more flicks
        if flicksArray.count > 1 {
            //flicks present, increment startIndex, hide default flick
            startIndex += 1
            flicks.1.isHidden = true
        }
        else {
            // only one flick, which is default flick
            flicks.1.isHidden = false
        }
        
        // get frame and create a size with zero with...will accum width as views are set
        var frame = flickScrollView.bounds
        frame.origin = CGPoint(x: 0, y: 0)
        var size = CGSize(width: 0, height: frame.size.height)
        
        // place flicks in sv...set contentSize when complete
        for index in startIndex..<flicksArray.count {
            let flick = flicksArray[index]
            flick.1.frame = frame
            frame.origin.x += frame.size.width
            size.width += frame.size.width
        }
        flickScrollView.contentSize = size
        
        // test for scrollToImageView...scroll to this flick if provided
        if let flick = scrollToFlick {
            flickScrollView.scrollRectToVisible(flick.1.frame, animated: false)
            flickTitleLabel.text = flick.0
        }
    }
}

// scrollView delegate methods
extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        // flickScrollView has stopped scrolling...update flickTitleLabel
        // to show title of current flick
        let index = indexOfVisibleFlick()
        flickTitleLabel.text = flicksArray[index].0
        
        // restore alpha of titleLabel
        flickTitleLabel.alpha = 1.0
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        // starting to scroll flickScrollView...dim title while scrolling...aesthetics
        flickTitleLabel.alpha = 0.3
    }
}
