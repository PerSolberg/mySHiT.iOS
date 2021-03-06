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
    func overlayBadge(_ modified : ChangeState) -> UIImage
    {
        var watermark : UIImage? = nil
        
        if modified == .Changed {
            watermark = Constant.Icon.watermarkChanged
        } else if modified == .New {
            watermark = Constant.Icon.watermarkNew
        }

        if let watermark = watermark {
            UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
            self.draw(in: CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
            watermark.draw(in: CGRect(x: self.size.width - watermark
                .size.width, y:self.size.height - watermark.size.height, width: watermark.size.width, height: watermark.size.height))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return result!
        } else {
            return self
        }
    }
}
