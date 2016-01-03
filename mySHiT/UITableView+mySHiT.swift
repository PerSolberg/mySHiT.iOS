//
//  UITableView+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-12-29.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

extension UITableView
{
    func setBackgroundMessage(messageText:String?) {
        if let messageText = messageText {
            let messageView = UILabel()
            //let messageView = UITextView()
        
            messageView.text = messageText
            messageView.textAlignment = .Center
            messageView.sizeToFit()

            //messageLabel.textColor = UIColor.cyanColor()
            //self.backgroundColor = UIColor.clearColor()
            dispatch_async(dispatch_get_main_queue(), {
                self.backgroundView = messageView
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), {
                self.backgroundView = nil
            })
        }
    }
}


