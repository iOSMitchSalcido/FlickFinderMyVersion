//
//  Flick.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/27/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About Flick.swift:
 Model object for photo's retrieved from Flickr. Maintains a title and image, and also a stored/computed property
 to imageView containing the image...Need references to imageView when populating scrollView
 */
import UIKit

class Flick {
    
    // model properties
    let title: String
    let image: UIImage
    
    // weak ref to imageView...may be held by arrays and superView of scrollView
    weak private var imageView: UIImageView?

    // init
    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
    }
    
    // computed property..returns iageView..creates if needed
    var flickImageView: UIImageView {
        
        if let _ = imageView {
            return imageView!
        }
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = image
        imageView = iv
        return imageView!
    }
}
