//
//  UIImageView+RSNetworking.swift
//  RSNetworkSample
//
//  Created by Jon Hoffman on 7/14/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    
    func setImageForURL(_ url: String, placeHolder: UIImage) -> Void{
        
        self.image = placeHolder
        setImageForURL(url)
        
    }
    
    func setImageForURL(_ urlStr: String) -> Void {
        let url = URL(string: urlStr)
        let client = RSURLRequest()
        client.imageFromURL(url!, completionHandler: {(response : URLResponse?, image: UIImage?, error: Error?) -> Void in
            
            self.image = image
            })
    }
    
    func setImageForRSTransaction(_ transaction:RSTransaction, placeHolder: UIImage) -> Void {
        self.image = placeHolder
        setImageForRSTransaction(transaction)
    }
    
    func setImageForRSTransaction(_ transaction:RSTransaction) -> Void {
        let RSRequest = RSTransactionRequest();
        
        RSRequest.imageFromRSTransaction(transaction, completionHandler: {(response: URLResponse?, image: UIImage?, error: Error?) -> Void in
            self.image = image
            })
        
      }
}
