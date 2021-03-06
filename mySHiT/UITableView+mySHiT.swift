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
    func setBackgroundMessage(_ messageText:String?) {
        if let messageText = messageText {
            DispatchQueue.main.async(execute: {
                let messageView = UILabel()
                
                messageView.text = messageText
                messageView.textAlignment = .center
                messageView.sizeToFit()
                
                self.backgroundView = messageView
            })
        }
        else
        {
            DispatchQueue.main.async(execute: {
                self.backgroundView = nil
            })
        }
    }
}


