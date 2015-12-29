//
//  UIImage+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-12-28.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

extension UIImage
{
    func overlayBadge(modified : ChangeState) -> UIImage
    {
        var watermark : UIImage? = nil
        
        if modified == .Changed {
            watermark = UIImage(named: "changed")
        } else if modified == .New {
            watermark = UIImage(named: "new")
        }

        if let watermark = watermark {
            UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
            self.drawInRect(CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
            watermark.drawInRect(CGRect(x: self.size.width - watermark
                .size.width, y:self.size.height - watermark.size.height, width: watermark.size.width, height: watermark.size.height))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return result
        } else {
            return self
        }
    }
}