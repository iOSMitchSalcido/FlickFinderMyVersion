//
//  FlickrAPI.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About FlickrAPI.swift:
 Functionality for Flickr API. Implementation of function for photo search.
 */
import Foundation
import UIKit


struct FlickrAPI {
    
    // error
    enum Errors: Swift.Error {
        case searchItems(String)
        case dataTask(String)
        case unavailableData(String)
    }
    
    // constants
    fileprivate let API_Scheme = "https"
    fileprivate let API_Host = "api.flickr.com"
    fileprivate let API_Path = "/services/rest"

    // base params for all searches used in this app
    private var baseParams = ["method": "flickr.photos.search",
                      "api_key": "3bc85d1817c25bfd73b8a05ff26a01c3",
                      "format": "json",
                      "extras": "url_m",
                      "nojsoncallback": "1",
                      "safe_search": "1"]
    
    // public search method
    func searchForFlick(phrase: String?, bbox: String?, completion: @escaping (Errors?, (String, UIImage)?) -> Void) {
        
        /*
         set phase search and bbox (geo) search params. Then test that both are non-nil before continuing search
         */
        var params = baseParams
        if let phrase = phrase {
            params["text"] = phrase
        }
        
        if let bbox = bbox {
            params["bbox"] = bbox
        }
        
        if params["text"] == nil && params["bbox"] == nil {
            completion(Errors.searchItems("Invalid search items. Check values in text fields."), nil)
        }
        else {
            flickrSearch(params, completion: completion)
        }
    }
}

// extension to handle requests
extension FlickrAPI {
    
    // flickr search method
    fileprivate func flickrSearch(_ params: [String: String], completion: @escaping (Errors?, (String, UIImage)?) -> Void) {
        
        // get url from params and create data task
        let request = urlForMethods(params)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            /* data task completion
             Completion handles detecting errors and valid data. Is called in two passes. First pass will retrieve
             JSON data to determine # of pages available for search. Second pass performs another search that includes
             a random page that was selected in pass 1
            */
            
            // error test
            guard error == nil else {
                completion(Errors.dataTask("Error in Flickr response. Try again"), nil)
                return
            }
            
            // valid status test
            guard let status = (response as? HTTPURLResponse)?.statusCode,
                status >= 200, status <= 299 else {
                    completion(Errors.dataTask("Bad network status"), nil)
                    return
            }
            
            // valid data returned
            guard let data = data else {
                completion(Errors.dataTask("Bad data returned from Flickr"), nil)
                return
            }
            
            // retrieve JSON object from data
            let jsonData: [String: AnyObject]!
            do {
                jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            }
            catch {
                completion(Errors.dataTask("Bad data returned from Flickr"), nil)
                return
            }
            
            // // valid Flickr API stat
            guard let stat = jsonData["stat"] as? String, stat == "ok" else {
                completion(Errors.dataTask("Flickr status error"), nil)
                return
            }
            
            // good data
            
            // retrieve photo's dictionary..top level dictionary return by Flickr
            guard let photosDictionary = jsonData["photos"] as? [String: AnyObject] else {
                completion(Errors.unavailableData("No photos returned from Flickr."), nil)
                return
            }
            
            // test if page was in search params
            if params["page"] == nil {
                
                // page not in search params..get a random page, new search with random page
                
                // get pages and photos/page that was returned in search
                guard let pages = photosDictionary["pages"] as? Int,
                    pages > 0, let perPage = photosDictionary["perpage"] as? Int else {
                        completion(Errors.unavailableData("No photo pages returned from Flickr."), nil)
                        return
                }
                
                // Flickr has 4000 photo limit. Get max allowable page search, generate a random page
                let pageLimit = min(pages, 4000 / perPage)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1

                // now have a random page to continue search.. create another set of "base" params
                // and include random page and per page in this search...conduct search
                var searchWithPageParams = params
                searchWithPageParams["page"] = "\(randomPage)"
                searchWithPageParams["perpage"] = "\(perPage)"
                self.flickrSearch(searchWithPageParams, completion: completion)
            }
            else {
                
                // page was included in params..
                // Now have dictionary made up of photos from page generated above
                
                // get photos array
                guard let photoArray = photosDictionary["photo"] as? [[String: AnyObject]],
                photoArray.count > 0 else {
                    completion(Errors.unavailableData("No photos returned from Flickr"), nil)
                    return
                }
                
                // create a random index and get a random photo
                let randonIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                let photoDictionary = photoArray[randonIndex] as [String: AnyObject]
                
                // get Flick title...use default if no title
                var flickrPhotoTitle = "Untitled Flick"
                if let photoTitle = photoDictionary["title"] as? String {
                    flickrPhotoTitle = photoTitle
                }
                
                // get image URL string
                guard let imageUrlString = photoDictionary["url_m"] as? String else {
                    completion(Errors.unavailableData("No photos returned from Flickr."), nil)
                    return
                }
                
                // create URL, get image data
                let imageUrl = URL(string: imageUrlString)!
                let imageData: Data!
                do {
                    imageData = try Data(contentsOf: imageUrl)
                }
                catch {
                    completion(Errors.dataTask("No Flick found."), nil)
                    return
                }
                
                // test for good image
                guard let image = UIImage(data: imageData) else {
                    completion(Errors.dataTask("No Flick found."), nil)
                    return
                }
                
                // now have good image (Flick) and photo title
                // fire completion using nil error and a dictionary created from title and image
                completion(nil, (flickrPhotoTitle, image))
            }
        }
        task.resume()
    }
    
    // create URL from params
    fileprivate func urlForMethods(_ methods: [String: String]) -> URL {
        
        var components = URLComponents()
        components.scheme = API_Scheme
        components.host = API_Host
        components.path = API_Path
        
        var queryItems = [URLQueryItem]()
        for (key, value) in methods {
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        components.queryItems = queryItems
        
        return components.url!
    }
}
