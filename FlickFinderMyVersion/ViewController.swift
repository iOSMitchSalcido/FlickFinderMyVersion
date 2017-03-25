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
        
        flickScrollView = UIScrollView(frame: backgroundView.bounds)
        flickScrollView.isPagingEnabled = true
        backgroundView.addSubview(flickScrollView)
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        backgroundView.addSubview(activityIndicator)

        defaultImageView = UIImageView()
        defaultImageView.image = UIImage(named: "DefaultImage")
        imageViewArray.append(defaultImageView)
        flickScrollView.addSubview(defaultImageView)
        print("scrollView: \(flickScrollView.subviews.count)")

        updateScrollView()
    }
    
    override func viewWillLayoutSubviews() {
    
    }
    
    func updateScrollView() {
        
        for imageView in imageViewArray {
            if imageView.superview == nil {
                flickScrollView.addSubview(imageView)
            }
        }
        
        if imageViewArray.count == 2 && imageViewArray.first == defaultImageView {
            let iv = imageViewArray.removeFirst()
            iv.removeFromSuperview()
        }
        
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
        
        frame.origin.x -= frame.size.width
        flickScrollView.scrollRectToVisible(frame, animated: true)
        //flickScrollView
        activityIndicator.frame.origin.x = backgroundView.bounds.size.width / 2.0 - activityIndicator.frame.width / 2.0
        activityIndicator.frame.origin.y = backgroundView.bounds.size.height / 2.0 - activityIndicator.frame.height / 2.0
    }
    
    func upSwipeGrDetected(_ gr: UISwipeGestureRecognizer) {
        print("upSwipe")
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
                    for (key, value) in  dict! {
                        
                        let imageView = UIImageView()
                        imageView.contentMode = .scaleAspectFit
                        imageView.image = value
                        self.imageViewArray.append(imageView)
                        
                        //dispatch
                        DispatchQueue.main.async {
                            self.flickTitleLabel.text = key
                            //self.flickScrollView.addSubview(imageView)
                            self.updateScrollView()
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
