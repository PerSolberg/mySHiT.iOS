//
//  UITextView+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-05-20.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

extension UITextView
{
    func setText(_ value: String?, detectChanges: Bool) {
        if (detectChanges && value != text) {
            backgroundColor = UIColor.yellow
        }
        text = value
    }

    
    func setText(_ value: NSAttributedString?, detectChanges: Bool) {
        if (detectChanges && value != attributedText) {
            backgroundColor = UIColor.yellow
        }
        attributedText = value
    }

    
    func alignBaseline(to label:UILabel!) {
        var baselineShift:CGFloat = 0.0
        if let myFont = self.font {
            baselineShift = (label.font.ascender - myFont.ascender)
        }
        self.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
    }


    func bubblePath(borderWidth: CGFloat, radius: CGFloat, triangleHeight:CGFloat, triangleEdge: Edge, trianglePosition:Position) -> UIBezierPath {
        self.sizeToFit()
        let contentSize = textContainer.size

        let rect = CGRect(x: 0, y:0, width: contentSize.width, height: contentSize.height).offsetBy(dx: radius, dy: radius )
        let path = UIBezierPath();
        let radius2 = radius - borderWidth / 2    // Radius adjusted for border width
        
        if triangleEdge == .left {
            switch trianglePosition {
            case .bottom:
                path.move(to: CGPoint(x: rect.minX - radius2, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX - radius2 - triangleHeight, y: rect.maxY - triangleHeight))
                path.addLine(to: CGPoint(x: rect.minX - radius2, y: rect.maxY - 2 * triangleHeight))
            case .centre:
                path.move(to: CGPoint(x: rect.minX - radius2, y: (rect.maxY + rect.minY) / 2 + triangleHeight))
                path.addLine(to: CGPoint(x: rect.minX - radius2 - triangleHeight, y: (rect.maxY + rect.minY) / 2))
                path.addLine(to: CGPoint(x: rect.minX - radius2, y: (rect.maxY + rect.minY) / 2 - triangleHeight))
            case .top:
                path.move(to: CGPoint(x: rect.minX - radius2, y: rect.minY + triangleHeight * 2))
                path.addLine(to: CGPoint(x: rect.minX - radius2 - triangleHeight, y: rect.minY + triangleHeight))
                path.addLine(to: CGPoint(x: rect.minX - radius2, y: rect.minY))
            default:
                os_log("Inconsistent edge and position", log: OSLog.general, type: .error)
            }
        }
        
        // Upper left corner
        path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.minY), radius: radius2, startAngle: CGFloat(Double.pi), endAngle: CGFloat(-Double.pi / 2), clockwise: true)

        if triangleEdge == .top {
            switch trianglePosition {
            case .left:
                path.addLine(to: CGPoint(x: rect.minX + triangleHeight, y: rect.minY - radius2 - triangleHeight))
                path.addLine(to: CGPoint(x: rect.minX + 2 * triangleHeight, y: rect.minY - radius2))
            case .centre:
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX) / 2 - triangleHeight, y: rect.minY - radius2))
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX ) / 2, y: rect.minY - radius2 - triangleHeight))
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX) / 2 + triangleHeight, y: rect.minY - radius2))
            case .right:
                path.addLine(to: CGPoint(x: rect.maxX - 2 * triangleHeight, y: rect.minY - radius2))
                path.addLine(to: CGPoint(x: rect.maxX - triangleHeight, y: rect.minY - radius2 - triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY - radius2))
            default:
                os_log("Inconsistent edge and position", log: OSLog.general, type: .error)
            }
        }
        
        // Upper right corner
        path.addArc(withCenter: CGPoint(x: rect.maxX, y: rect.minY), radius: radius2, startAngle: CGFloat(-Double.pi / 2), endAngle: 0, clockwise: true)
        
        if triangleEdge == .right {
            switch trianglePosition {
            case .top:
                path.addLine(to: CGPoint(x: rect.maxX + radius2 + triangleHeight, y: rect.minY + triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX + radius2, y: rect.minY + 2 * triangleHeight))
            case .centre:
                path.addLine(to: CGPoint(x: rect.maxX + radius2, y: (rect.maxY + rect.minY) / 2 - triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX + radius2 + triangleHeight, y: (rect.maxY + rect.minY) / 2))
                path.addLine(to: CGPoint(x: rect.maxX + radius2, y: (rect.maxY + rect.minY) / 2 + triangleHeight))
            case .bottom:
                path.addLine(to: CGPoint(x: rect.maxX + radius2, y: rect.maxY - 2 * triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX + radius2 + triangleHeight, y: rect.maxY - triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX + radius2, y: rect.maxY))
            default:
                os_log("Inconsistent edge and position", log: OSLog.general, type: .error)
            }
        }

        // Lower right corner
        path.addArc(withCenter: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius2, startAngle: 0, endAngle: CGFloat(Double.pi / 2), clockwise: true)

        if triangleEdge == .bottom {
            switch trianglePosition {
            case .right:
                path.addLine(to: CGPoint(x: rect.maxX - triangleHeight, y: rect.maxY + radius2 + triangleHeight))
                path.addLine(to: CGPoint(x: rect.maxX - 2 * triangleHeight, y: rect.maxY + radius2))
            case .centre:
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX) / 2 + triangleHeight, y: rect.maxY + radius2))
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX ) / 2, y: rect.maxY + radius2 + triangleHeight))
                path.addLine(to: CGPoint(x: (rect.maxX + rect.minX) / 2 - triangleHeight, y: rect.maxY + radius2))
            case .left:
                path.addLine(to: CGPoint(x: rect.minX + 2 * triangleHeight, y: rect.maxY + radius2))
                path.addLine(to: CGPoint(x: rect.minX + triangleHeight, y: rect.maxY + radius2 + triangleHeight))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + radius2))
            default:
                os_log("Inconsistent edge and position", log: OSLog.general, type: .error)
            }
        }
        
        // Lower left corner
        path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.maxY), radius: radius2, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: true)
        
        path.close()
        return path
    }
    
}
