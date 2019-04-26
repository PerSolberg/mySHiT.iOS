//
//  UIButton+RSNetworking.swift
//  iTunesSearch
//
//  Created by Jon Hoffman on 8/25/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import UIKit

extension UIButton {
    func setButtonImageForURL(_ urlStr: String, placeHolder: UIImage, state: UIControl.State) -> Void{
        self.setBackgroundImage(placeHolder, for:state)
        setButtonImageForURL(urlStr,state: state)
    }
    
    func setButtonImageForURL(_ urlStr: String, state: UIControl.State) -> Void {
        let url = URL(string: urlStr)
        let client = RSURLRequest()
        client.imageFromURL(url!, completionHandler: {(response : URLResponse?, image: UIImage?, error: Error?) -> Void in
            self.setBackgroundImage(image, for:state)

        })
    }
 
    func setButtonImageForRSTransaction(_ transaction:RSTransaction, placeHolder: UIImage, state: UIControl.State) -> Void {
        self.setBackgroundImage(placeHolder, for:state)
        setButtonImageForRSTransaction(transaction, state: state)
    }
    
    func setButtonImageForRSTransaction(_ transaction:RSTransaction, state: UIControl.State) -> Void {
        let RSRequest = RSTransactionRequest();
        
        RSRequest.imageFromRSTransaction(transaction, completionHandler: {(response: URLResponse?, image: UIImage?, error: Error?) -> Void in
            self.setBackgroundImage(image, for:state)
        })
        
    }

}
