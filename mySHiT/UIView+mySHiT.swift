//
//  UIView+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-26.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

extension UIView
{
    enum Edge:String {
        case top    = "T"
        case bottom = "B"
        case left   = "L"
        case right  = "R"
    }
    
    enum Position:String {
        case top    = "T"
        case bottom = "B"
        case left   = "L"
        case right  = "R"
        case centre = "C"
    }
    
    fileprivate func processSubviews(_ recurse: Bool, processChildrenFirst: Bool, level:Int, action : (_ view: UIView, _ level:Int) -> Void)
    {
        //print("Processing subviews for " + self.description)
        if !processChildrenFirst {
            action(self, level)
        }
        for view in subviews {
            view.processSubviews(recurse, processChildrenFirst: processChildrenFirst, level: level + 1, action: action)
        }
        if processChildrenFirst {
            action(self, level)
        }
    }

    
    func processSubviews(_ recurse: Bool, processChildrenFirst: Bool, action : (_ view: UIView, _ level:Int) -> Void)
    {
        //print("Processing subviews for " + self.description)
        processSubviews(recurse, processChildrenFirst: processChildrenFirst, level: 1, action: action)
    }

    
    func addDictionaryAsGrid(_ dictionary: NSDictionary, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {
        //print("Adding stuff here")
        if dictionary.count < 1 {
            print("Dictionary empty, returning")
            return
        }

        // Find root view (so we can add constraint)
        var rootView = self
        if constrainValueFieldWidthToView != nil {
            while rootView.superview != nil {
                rootView = rootView.superview!
            }
        }
        
        // Set up vertical stack view and add it to main view
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 8;
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.isUserInteractionEnabled = true
        self.addSubview(verticalStackView)
            
        // Constrain vertical stack view to self
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .trailing , relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0))
        //if self.isKindOfClass(UIScrollView) {
            // If we're adding to a scroll view, we need to constrain the bottom, otherwise not
            self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        //}
        
        var firstValueField: UIView?
        for (key, value) in dictionary {
            //print("Entry: Key = \(key), value = \(value)")
            //if (value as AnyObject).isKind(of: NSNull) {
            if (value is NSNull) {
                // Empty element - ignore
                continue
            }

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isUserInteractionEnabled = true
            //label.font = flightNoTextField.font //flightNoLabel.font
            label.contentMode = .left
            label.setContentHuggingPriority(horisontalHuggingForLabel, for: .horizontal)
            label.setContentHuggingPriority(verticalHuggingForLabel, for: .vertical)
            label.text = key as? String
            
            // Set up text wrapper
            let valueWrapper = UIView()
            valueWrapper.translatesAutoresizingMaskIntoConstraints = false
            valueWrapper.isUserInteractionEnabled = true
            valueWrapper.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
            valueWrapper.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)

//            if (value as AnyObject).isKind(of: NSArray) {
            if (value is NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            //} else if (value as AnyObject).isKind(of: NSDictionary) {
            } else if (value is NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                valueField.isUserInteractionEnabled = true
                //value.font = flightNoTextField.font
                valueField.isUserInteractionEnabled = true
                valueField.isEditable = false
                valueField.isSelectable = true
                valueField.isScrollEnabled = false
                //valueField.textContainerInset = UIEdgeInsetsZero
                valueField.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
                //if (value as AnyObject).isKind(of: NSAttributedString) {
                if (value is NSAttributedString) {
                    valueField.attributedText = value as! NSAttributedString
                //} else if (value as AnyObject).isKind(of: NSString) {
                } else if (value is NSString) {
                    valueField.text = value as! String
                //} else if (value as AnyObject).isKind(of: NSNumber) {
                } else if (value is NSNumber) {
                    valueField.text = String(describing: value as! NSNumber)
                } else {
                    print("Unsupported data type for entry")
                }
                var baselineShift:CGFloat = 0.0
                if let valueFont = valueField.font {
                    //print("label font: line height=\(label.font.lineHeight), leading=\(label.font.leading), x height=\(label.font.xHeight), ascender=\(label.font.ascender)")
                    //print("value font: line height=\(valueFont.lineHeight), leading=\(valueFont.leading), x height=\(valueFont.xHeight), ascender=\(valueFont.ascender)")
                    //baselineShift = label.font.lineHeight - valueFont.lineHeight
                    baselineShift = /*round*/(label.font.ascender - valueFont.ascender)
                }
                valueField.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
                valueField.textContainer.lineFragmentPadding = 0.0

                valueWrapper.addSubview(valueField)
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .leading, relatedBy: .equal, toItem: valueWrapper, attribute: .leading, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .trailing , relatedBy: .equal, toItem: valueField, attribute: .trailing, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .top, relatedBy: .equal, toItem: valueWrapper, attribute: .top, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .bottom, relatedBy: .equal, toItem: valueField, attribute: .bottom, multiplier: 1.0, constant: 0.0))
            }

            let horisontalStackView = UIStackView(arrangedSubviews: [label , valueWrapper])
            horisontalStackView.isUserInteractionEnabled = true
            horisontalStackView.axis = .horizontal
            horisontalStackView.distribution = .fill
            horisontalStackView.alignment = .top // .FirstBaseline
            horisontalStackView.spacing = 8;
            horisontalStackView.translatesAutoresizingMaskIntoConstraints = false
                    
            verticalStackView.addArrangedSubview(horisontalStackView)

            // Constrain all value fields to same width
            if let firstValueField = firstValueField {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .width, relatedBy: .equal, toItem: firstValueField, attribute: .width, multiplier: 1.0, constant: 0)
                verticalStackView.addConstraint(valueWidthConstraint)
            } else {
                firstValueField = valueWrapper
            }
            // Constrain to "external" view
            if constrainValueFieldWidthToView != nil {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .width, relatedBy: .equal, toItem: constrainValueFieldWidthToView, attribute: .width, multiplier: 1.0, constant: 0)
                rootView.addConstraint(valueWidthConstraint)
            }
        }
        
        if let selfAsScrollView = self as? UIScrollView {
            print("Adding to scroll view - setting size")
            verticalStackView.layoutIfNeeded()
            //print("Scroll view content size = \(verticalStackView.bounds.size), frame = \(verticalStackView.frame), indicators H/V = \(selfAsScrollView.showsHorizontalScrollIndicator)/\(selfAsScrollView.showsVerticalScrollIndicator)")
            selfAsScrollView.contentSize = verticalStackView.bounds.size
        }
    }


    func addArrayAsVerticalStack(_ array: NSArray, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {
        print("Adding array here")
        if array.count < 1 {
            print("Array empty, returning")
            return
        }
        
        // Find root view (so we can add constraint)
        var rootView = self
        if constrainValueFieldWidthToView != nil {
            while rootView.superview != nil {
                rootView = rootView.superview!
            }
        }
        
        // Set up vertical stack view and add it to main view
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 8;
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(verticalStackView)
        
        // Constrain vertical stack view to self
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .trailing , relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
        var firstValueField: UIView?
        for value in array {
            //print("Entry: \(value)")
            //if (value as AnyObject).isKind(of: NSNull) {
            if (value is NSNull) {
                // Empty element - ignore
                continue
            }
            
            // Set up text wrapper
            let valueWrapper = UIView()
            valueWrapper.translatesAutoresizingMaskIntoConstraints = false
            valueWrapper.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
            valueWrapper.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
            
            //if (value as AnyObject).isKind(of: NSArray) {
            if (value is NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            //} else if (value as AnyObject).isKind(of: NSDictionary) {
            } else if (value is NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                //value.font = flightNoTextField.font
                valueField.isUserInteractionEnabled = true
                valueField.isEditable = false
                valueField.isSelectable = true
                valueField.isScrollEnabled = false
                valueField.textContainerInset = UIEdgeInsets.zero
                valueField.textContainer.lineFragmentPadding = 0.0
                valueField.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
                //if (value as AnyObject).isKind(of: NSString) {
                if (value is NSString) {
                    valueField.text = value as! String
                //} else if (value as AnyObject).isKind(of: NSNumber) {
                } else if (value is NSNumber) {
                    valueField.text = String(describing: value as! NSNumber)
                }
                
                valueWrapper.addSubview(valueField)
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .leading, relatedBy: .equal, toItem: valueWrapper, attribute: .leading, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .trailing , relatedBy: .equal, toItem: valueField, attribute: .trailing, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .top, relatedBy: .equal, toItem: valueWrapper, attribute: .top, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .bottom, relatedBy: .equal, toItem: valueField, attribute: .bottom, multiplier: 1.0, constant: 0.0))
            }
            
            verticalStackView.addArrangedSubview(valueWrapper)
            
            // Constrain all value fields to same width
            if let firstValueField = firstValueField {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .width, relatedBy: .equal, toItem: firstValueField, attribute: .width, multiplier: 1.0, constant: 0)
                verticalStackView.addConstraint(valueWidthConstraint)
            } else {
                firstValueField = valueWrapper
            }
            // Constrain to "external" view
            if constrainValueFieldWidthToView != nil {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .width, relatedBy: .equal, toItem: constrainValueFieldWidthToView, attribute: .width, multiplier: 1.0, constant: 0)
                rootView.addConstraint(valueWidthConstraint)
            }
        }
        
        verticalStackView.sizeToFit()
        if let selfAsScrollView = self as? UIScrollView {
            selfAsScrollView.contentSize = verticalStackView.bounds.size
        }
    }
    
    
    func colourSubviews() {
        self.processSubviews(true, processChildrenFirst: false, action: { (view, level) -> Void in
            print("\(level): \(view.debugDescription)")
            let colors = [UIColor.yellow, UIColor.lightGray, UIColor.blue, UIColor.brown, UIColor.gray, UIColor.green, UIColor.magenta]
            if level < colors.count {
                view.backgroundColor = colors[level]
            } else {
                view.backgroundColor = UIColor.red
            }
        })
    }
    
    func bubblePath(borderWidth: CGFloat, radius: CGFloat, triangleHeight:CGFloat, triangleEdge: Edge, trianglePosition:Position) -> UIBezierPath {
        let contentSize = self.intrinsicContentSize
        
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
                print("Inconsistent edge and position")
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
                print("Inconsistent edge and position")
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
                print("Inconsistent edge and position")
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
                print("Inconsistent edge and position")
            }
        }
        
        // Lower left corner
        path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.maxY), radius: radius2, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: true)
        
        path.close()
        return path
    }
}
