//
//  RSTransactionRequest.swift
//  RSNetworkSample
//
//  Created by Jon Hoffman on 7/25/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

private func urlEncode(_ s: String) -> String? {
    return s.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
}

class RSTransactionRequest: NSObject {
    
    let dictKey = "results"
    
    typealias dataFromRSTransactionCompletionClosure = ((URLResponse?, Data?, Error?) -> Void)
    typealias stringFromRSTransactionCompletionClosure = ((URLResponse?, NSString?, Error?) -> Void)
    typealias dictionaryFromRSTransactionCompletionClosure = ((URLResponse?, NSDictionary?, Error?) -> Void)
    typealias imageFromRSTransactionCompletionClosure = ((URLResponse?, UIImage?, Error?) -> Void)
    
    
    func dataFromRSTransaction(_ transaction: RSTransaction, completionHandler handler: @escaping dataFromRSTransactionCompletionClosure)
    {
        if (transaction.transactionType == RSTransactionType.get) {
            dataFromRSTransactionGet(transaction, completionHandler: handler);
        } else if(transaction.transactionType == RSTransactionType.post) {
            dataFromRSTransactionPost(transaction, completionHandler: handler);
        }
    }

    fileprivate func dataFromRSTransactionPost(_ transaction: RSTransaction, completionHandler handler: @escaping dataFromRSTransactionCompletionClosure)
    {

        let sessionConfiguration = URLSessionConfiguration.default
        
        let urlString = transaction.getFullURLString() + "?" + dictionaryToQueryString(transaction.parameters)
        let url: URL = URL(string: urlString)!
        
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        var params = Data()
        if let payload = transaction.payload {
            //params = dictionaryToQueryString(payload)
            params = try! JSONSerialization.data(withJSONObject: payload, options: .init(rawValue: 0))
            print("JSON payload:")
            print(params)
            //using: String.Encoding.utf8)
        }
        request.httpBody = params //params.
        //request.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: true)
        
        let urlSession = URLSession(configuration:sessionConfiguration, delegate: nil, delegateQueue: nil)
        
        urlSession.dataTask(with: request, completionHandler: {(responseData: Data?, response: URLResponse?, error: Error?) -> Void in
            
            handler(response, responseData, error)
        }).resume()
    }

    fileprivate func dataFromRSTransactionGet(_ transaction: RSTransaction, completionHandler handler: @escaping dataFromRSTransactionCompletionClosure)
    {
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let urlString = transaction.getFullURLString() + "?" + dictionaryToQueryString(transaction.parameters)
        let url: URL = URL(string: urlString)!
        //print("URL = \(urlString)")
        
        var request = URLRequest(url:url)
        request.httpMethod = "GET"
        let urlSession = URLSession(configuration:sessionConfiguration, delegate: nil, delegateQueue: nil)
        
        urlSession.dataTask(with: request, completionHandler: {(responseData: Data?, response: URLResponse?, error: Error?) -> Void in
            
            handler(response, responseData, error)
        }).resume()
    }

    func stringFromRSTransaction(_ transaction: RSTransaction, completionHandler handler: @escaping stringFromRSTransactionCompletionClosure) {
        dataFromRSTransaction(transaction, completionHandler: {(response: URLResponse!, responseData: Data!, error: Error!) -> Void in
            
            let responseString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue)
            handler(response,responseString,error)
        } as! (URLResponse?, Data?, Error?) -> Void)
    }
    
    
    func dictionaryFromRSTransaction(_ transaction: RSTransaction, completionHandler handler: @escaping dictionaryFromRSTransactionCompletionClosure) {
        dataFromRSTransaction(transaction, completionHandler: {(response: URLResponse?, responseData: Data?, error: Error?) -> Void in
            
            if error != nil {
                handler(response, nil, error)
                return
            }
            
            /*if let responseData = responseData {
                print("Response (base64): " + (responseData.base64EncodedString()))
            } else {
                print("Empty response")
            }*/
            
            let resultDictionary = NSMutableDictionary()
            var jsonResponse : Any?
            var errMsg: String = ""
            do {
                jsonResponse  = try JSONSerialization.jsonObject(with: (responseData!), options: JSONSerialization.ReadingOptions.allowFragments)
            }
            catch let error as NSError {
                errMsg = "A JSON parsing error occurred, here are the details:\n \(error) \n \(responseData)"
            }
            //print("JSON parsed successfully")
            if let jsonResponse = jsonResponse as? [String:Any] {
                //print(jsonResponse)
                resultDictionary.setDictionary(jsonResponse)
                //switch jsonResponse {
                //case is NSDictionary:
                //    resultDictionary = jsonResponse as NSMutableDictionary
                //case is NSArray:
                //    resultDictionary[self.dictKey] = jsonResponse
                //default:
                //    resultDictionary[self.dictKey] = ""
                //}
            } else {
                resultDictionary[self.dictKey] = errMsg
            }
            //print("JSON Dictionary = \(resultDictionary)")
            handler(response, resultDictionary.copy() as? NSDictionary, error)
        } /* as! (URLResponse?, Data?, Error?) -> Void */)
    }
    
    
    func imageFromRSTransaction(_ transaction: RSTransaction, completionHandler handler: @escaping imageFromRSTransactionCompletionClosure) {
        dataFromRSTransaction(transaction, completionHandler: {(response: URLResponse?, responseData: Data?, error: Error?) -> Void in
            
            if error != nil {
                handler(response,nil,error)
                return
            }
            
            let image = UIImage(data: responseData!)
            handler(response,image?.copy() as! UIImage?, error)
        } /* as! (URLResponse?, Data?, Error?) -> Void */)
    }
    
    
    fileprivate func dictionaryToQueryString(_ dict: [String : String]) -> String {
        var parts = [String]()
        for (key, value) in dict {
            if let keyEncoded = urlEncode(key), let valueEncoded = urlEncode(value) {
                parts.append(keyEncoded + "=" + valueEncoded);
            }
        }
        return parts.joined(separator: "&")

    }
}
