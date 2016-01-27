//
//  DataManager.swift
//  AreaDistanceCal
//
//  Created by Yuan Yinhuan on 15/11/6.
//  Copyright (c) 2015年 Jun Dang. All rights reserved.
//

import Foundation


class DataManager {
    
    class func getLocationFromGoogle(address: String, success: ((LocationData: NSData!) -> Void)) {
        let addressURL = "https://maps.googleapis.com/maps/api/geocode/json?address=" + address + "&key=AIzaSyBdTOGf2Apyxjck8RxFk2ffcYTnGU7btk8"
        //let urlString = addressURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let urlString = addressURL.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: urlString!)
        
        if url != nil {
            loadDataFromURL(url!, completion: { (data, error) -> Void in
                if let urlData = data {
                    
                    success(LocationData: urlData)
                }
            })

        }
        
    }

    class func loadDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
        let session = NSURLSession.sharedSession()
        
        // Use NSURLSession to get data from an NSURL
        let loadDataTask = session.dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let responseError = error {
                completion(data: nil, error: responseError)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain:"ca.beida", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code has unexpected value."])
                    completion(data: nil, error: statusError)
                } else {
                    completion(data: data, error: nil)
                }
            }
        })
        
        loadDataTask.resume()
    }
}