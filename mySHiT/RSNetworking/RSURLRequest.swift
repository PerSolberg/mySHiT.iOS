//
//  RSURLRequest.swift
//  RSNetworkSample
//
//  Created by Jon Hoffman on 7/25/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration


class RSURLRequest: NSObject {
    
    let dictKey = "results"
    
    typealias dataFromURLCompletionClosure = ((URLResponse?, Data?, NSError?) -> Void)
    typealias stringFromURLCompletionClosure = ((URLResponse?, NSString?, NSError?) -> Void)
    typealias dictionaryFromURLCompletionClosure = ((URLResponse?, NSDictionary?, NSError?) -> Void)
    typealias imageFromURLCompletionClosure = ((URLResponse?, UIImage?, NSError?) -> Void)
    
    
    func dataFromURL(_ url : URL, completionHandler handler: @escaping dataFromURLCompletionClosure) {
        
        let sessionConfiguration = URLSessionConfiguration.default
        let request = URLRequest(url:url)
        let urlSession = URLSession(configuration:sessionConfiguration, delegate: nil, delegateQueue: nil)
        
        
        _ = urlSession.dataTask(with: request, completionHandler: {(responseData: Data?, response: URLResponse?, error: NSError?) -> Void in
            
            handler(response,responseData,error)
        } as! (Data?, URLResponse?, Error?) -> Void).resume();
        
    }
    
    
    func stringFromURL(_ url : URL, completionHandler handler: @escaping stringFromURLCompletionClosure) {
        dataFromURL(url, completionHandler: {(response: URLResponse!, responseData: Data!, error: NSError!) -> Void in
            
            let responseString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue)
            handler(response,responseString,error)
        } as! RSURLRequest.dataFromURLCompletionClosure)
    }
    
    
    func dictionaryFromJsonURL(_ url : URL, completionHandler handler: @escaping dictionaryFromURLCompletionClosure) {
        dataFromURL(url, completionHandler: {(response: URLResponse!, responseData: Data!, error: NSError!) -> Void in
            
            if error != nil {
                handler(response,nil,error)
                return
            }
            
            var resultDictionary = NSMutableDictionary()
            var jsonResponse: Any?
            do {
                jsonResponse  = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)
            } catch {}
            
            if let jsonResponse = jsonResponse {
                switch jsonResponse {
                case is NSDictionary:
                    resultDictionary = jsonResponse as! NSMutableDictionary
                case is NSArray:
                    resultDictionary[self.dictKey] = jsonResponse
                default:
                    resultDictionary[self.dictKey] = ""
                }
            } else {
                resultDictionary[self.dictKey] = ""
            }
            handler(response, (resultDictionary.copy() as! NSDictionary), error)
            
        } as! RSURLRequest.dataFromURLCompletionClosure)
    }
    
    func imageFromURL(_ url : URL, completionHandler handler: @escaping imageFromURLCompletionClosure) {
        dataFromURL(url, completionHandler: {(response: URLResponse!, responseData: Data!, error: NSError!) -> Void in
            
            if error != nil {
                handler(response,nil,error)
                return
            }
            
            let image = UIImage(data: responseData)
            handler(response, (image?.copy() as! UIImage), error)
        } as! RSURLRequest.dataFromURLCompletionClosure)
    }
    
    
    
}
