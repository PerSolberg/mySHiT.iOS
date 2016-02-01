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
    private func processSubviews(recurse: Bool, processChildrenFirst: Bool, level:Int, action : (view: UIView, level:Int) -> Void)
    {
        //print("Processing subviews for " + self.description)
        if !processChildrenFirst {
            action(view: self, level:level)
        }
        for view in subviews {
            view.processSubviews(recurse, processChildrenFirst: processChildrenFirst, level: level + 1, action: action)
        }
        if processChildrenFirst {
            action(view: self, level:level)
        }
    }

    
    func processSubviews(recurse: Bool, processChildrenFirst: Bool, action : (view: UIView, level:Int) -> Void)
    {
        //print("Processing subviews for " + self.description)
        processSubviews(recurse, processChildrenFirst: processChildrenFirst, level: 1, action: action)
    }

    
    func addDictionaryAsGrid(dictionary: NSDictionary, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {
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
        verticalStackView.axis = .Vertical
        verticalStackView.distribution = .Fill
        verticalStackView.alignment = .Fill
        verticalStackView.spacing = 8;
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.userInteractionEnabled = true
        self.addSubview(verticalStackView)
            
        // Constrain vertical stack view to self
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Trailing , relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0))
        //if self.isKindOfClass(UIScrollView) {
            // If we're adding to a scroll view, we need to constrain the bottom, otherwise not
            self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        //}
        
        var firstValueField: UIView?
        for (key, value) in dictionary {
            //print("Entry: Key = \(key), value = \(value)")
            if value.isKindOfClass(NSNull) {
                // Empty element - ignore
                continue
            }

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.userInteractionEnabled = true
            //label.font = flightNoTextField.font //flightNoLabel.font
            label.contentMode = .Left
            label.setContentHuggingPriority(horisontalHuggingForLabel, forAxis: .Horizontal)
            label.setContentHuggingPriority(verticalHuggingForLabel, forAxis: .Vertical)
            label.text = key as? String
            
            // Set up text wrapper
            let valueWrapper = UIView()
            valueWrapper.translatesAutoresizingMaskIntoConstraints = false
            valueWrapper.userInteractionEnabled = true
            valueWrapper.setContentHuggingPriority(horisontalHuggingForValue, forAxis: .Horizontal)
            valueWrapper.setContentHuggingPriority(verticalHuggingForValue, forAxis: .Vertical)

            if value.isKindOfClass(NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else if value.isKindOfClass(NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                valueField.userInteractionEnabled = true
                //value.font = flightNoTextField.font
                valueField.userInteractionEnabled = true
                valueField.editable = false
                valueField.selectable = true
                valueField.scrollEnabled = false
                //valueField.textContainerInset = UIEdgeInsetsZero
                valueField.setContentHuggingPriority(horisontalHuggingForValue, forAxis: .Horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, forAxis: .Vertical)
                if value.isKindOfClass(NSAttributedString) {
                    valueField.attributedText = value as! NSAttributedString
                } else if value.isKindOfClass(NSString) {
                    valueField.text = value as! String
                } else if value.isKindOfClass(NSNumber) {
                    valueField.text = String(value as! NSNumber)
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
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .Leading, relatedBy: .Equal, toItem: valueWrapper, attribute: .Leading, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Trailing , relatedBy: .Equal, toItem: valueField, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .Top, relatedBy: .Equal, toItem: valueWrapper, attribute: .Top, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Bottom, relatedBy: .Equal, toItem: valueField, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
            }

            let horisontalStackView = UIStackView(arrangedSubviews: [label , valueWrapper])
            horisontalStackView.userInteractionEnabled = true
            horisontalStackView.axis = .Horizontal
            horisontalStackView.distribution = .Fill
            horisontalStackView.alignment = .Top // .FirstBaseline
            horisontalStackView.spacing = 8;
            horisontalStackView.translatesAutoresizingMaskIntoConstraints = false
                    
            verticalStackView.addArrangedSubview(horisontalStackView)

            // Constrain all value fields to same width
            if let firstValueField = firstValueField {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .Width, relatedBy: .Equal, toItem: firstValueField, attribute: .Width, multiplier: 1.0, constant: 0)
                verticalStackView.addConstraint(valueWidthConstraint)
            } else {
                firstValueField = valueWrapper
            }
            // Constrain to "external" view
            if constrainValueFieldWidthToView != nil {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .Width, relatedBy: .Equal, toItem: constrainValueFieldWidthToView, attribute: .Width, multiplier: 1.0, constant: 0)
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


    func addArrayAsVerticalStack(array: NSArray, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {
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
        verticalStackView.axis = .Vertical
        verticalStackView.distribution = .Fill
        verticalStackView.alignment = .Fill
        verticalStackView.spacing = 8;
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(verticalStackView)
        
        // Constrain vertical stack view to self
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Trailing , relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        
        var firstValueField: UIView?
        for value in array {
            //print("Entry: \(value)")
            if value.isKindOfClass(NSNull) {
                // Empty element - ignore
                continue
            }
            
            // Set up text wrapper
            let valueWrapper = UIView()
            valueWrapper.translatesAutoresizingMaskIntoConstraints = false
            valueWrapper.setContentHuggingPriority(horisontalHuggingForValue, forAxis: .Horizontal)
            valueWrapper.setContentHuggingPriority(verticalHuggingForValue, forAxis: .Vertical)
            
            if value.isKindOfClass(NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else if value.isKindOfClass(NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                //value.font = flightNoTextField.font
                valueField.userInteractionEnabled = true
                valueField.editable = false
                valueField.selectable = true
                valueField.scrollEnabled = false
                valueField.textContainerInset = UIEdgeInsetsZero
                valueField.textContainer.lineFragmentPadding = 0.0
                valueField.setContentHuggingPriority(horisontalHuggingForValue, forAxis: .Horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, forAxis: .Vertical)
                if value.isKindOfClass(NSString) {
                    valueField.text = value as! String
                } else if value.isKindOfClass(NSNumber) {
                    valueField.text = String(value as! NSNumber)
                }
                
                valueWrapper.addSubview(valueField)
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .Leading, relatedBy: .Equal, toItem: valueWrapper, attribute: .Leading, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Trailing , relatedBy: .Equal, toItem: valueField, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueField, attribute: .Top, relatedBy: .Equal, toItem: valueWrapper, attribute: .Top, multiplier: 1.0, constant: 0.0))
                valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Bottom, relatedBy: .Equal, toItem: valueField, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
            }
            
            verticalStackView.addArrangedSubview(valueWrapper)
            
            // Constrain all value fields to same width
            if let firstValueField = firstValueField {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .Width, relatedBy: .Equal, toItem: firstValueField, attribute: .Width, multiplier: 1.0, constant: 0)
                verticalStackView.addConstraint(valueWidthConstraint)
            } else {
                firstValueField = valueWrapper
            }
            // Constrain to "external" view
            if constrainValueFieldWidthToView != nil {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .Width, relatedBy: .Equal, toItem: constrainValueFieldWidthToView, attribute: .Width, multiplier: 1.0, constant: 0)
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
            let colors = [UIColor.yellowColor(), UIColor.lightGrayColor(), UIColor.blueColor(), UIColor.brownColor(), UIColor.grayColor(), UIColor.greenColor(), UIColor.magentaColor()]
            if level < colors.count {
                view.backgroundColor = colors[level]
            } else {
                view.backgroundColor = UIColor.redColor()
            }
        })
    }
}