//
//  FlickrAPI.swift
//  FlickFinderMyVersion
//
//  Created by Online Training on 3/20/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

import Foundation
import UIKit

struct FlickrAPI {
    
    enum Errors: Swift.Error {
        case searchItems(String)
        case dataTask(String)
    }
    
    fileprivate let API_Scheme = "https"
    fileprivate let API_Host = "api.flickr.com"
    fileprivate let API_Path = "/services/rest"

    private var baseParams = ["method": "flickr.photos.search",
                      "api_key": "3bc85d1817c25bfd73b8a05ff26a01c3",
                      "format": "json",
                      "extras": "url_m",
                      "nojsoncallback": "1",
                      "safe_search": "1"]
    
    func searchForFlick(phrase: String?, bbox: String?, completion: @escaping (Errors?, [[String:UIImage]]?) -> Void) {
        
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

extension FlickrAPI {
    
    fileprivate func flickrSearch(_ params: [String: String], completion: @escaping (Errors?, [[String:UIImage]]?) -> Void) {
        
        print(urlForMethods(params))
        
        let request = urlForMethods(params)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            guard error == nil else {
                completion(Errors.dataTask("Error in Flickr response. Try again"), nil)
                return
            }
            
            guard let status = (response as? HTTPURLResponse)?.statusCode,
                status >= 200, status <= 299 else {
                    completion(Errors.dataTask("Bad network status"), nil)
                    return
            }
            
            guard let data = data else {
                completion(Errors.dataTask("Bad data returned from Flickr"), nil)
                return
            }
            
            let jsonData: [String: AnyObject]!
            do {
                jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            }
            catch {
                completion(Errors.dataTask("Bad data returned from Flickr"), nil)
                return
            }
            
            guard let stat = jsonData["stat"] as? String, stat == "ok" else {
                completion(Errors.dataTask("Flickr status error"), nil)
                return
            }
            
            // good data
            
            // test if page was in search params
            if params["page"] == nil {
                // page not in search params..get a random page, new search with random page
                var searchWithPageParams = params
                searchWithPageParams["page"] = "1"
                self.flickrSearch(searchWithPageParams, completion: completion)
            }
            else {
                
                guard let photosDictionary = jsonData["photos"] as? [String: AnyObject],
                    let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    completion(Errors.dataTask("No Flicks returned from Flickr"), nil)
                    return
                }
                
                let randonIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                let photoDictionary = photoArray[randonIndex] as [String: AnyObject]
                
                var flickrPhotoTitle = "Untitled Flick"
                if let photoTitle = photoDictionary["title"] as? String {
                    flickrPhotoTitle = photoTitle
                }
                
                guard let imageUrlString = photoDictionary["url_m"] as? String else {
                    completion(Errors.dataTask("No Flick's found."), nil)
                    return
                }
                
                let imageUrl = URL(string: imageUrlString)!
                
                let imageData: Data!
                do {
                    imageData = try Data(contentsOf: imageUrl)
                }
                catch {
                    completion(Errors.dataTask("No Flick found."), nil)
                    return
                }
                
                let image = UIImage(data: imageData)
                completion(nil, [[flickrPhotoTitle: image!]])
            }
        }
        task.resume()
    }
    
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
