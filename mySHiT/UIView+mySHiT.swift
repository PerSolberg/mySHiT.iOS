//
//  UIView+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-26.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import os

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
        processSubviews(recurse, processChildrenFirst: processChildrenFirst, level: 1, action: action)
    }

    
    func addDictionaryAsGrid(_ dictionary: NSDictionary, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {
        addDictionaryAsGrid(dictionary, oldDictionary: nil, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: constrainValueFieldWidthToView, highlightChanges: false)
    }

    
    func addDictionaryAsGrid(_ dictionary: NSDictionary, oldDictionary: NSDictionary?, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?, highlightChanges: Bool) {

        // First remove any existing elements
        for sv in self.subviews {
            sv.removeFromSuperview()
        }
        
        if dictionary.count < 1 {
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
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
        var firstValueField: UIView?
        for (key, value) in dictionary {
            var changed = false
            if (value is NSNull) {
                // Empty element - ignore
                continue
            }
            if highlightChanges, let oldDictionary = oldDictionary {
                if ( oldDictionary[key] is NSNull ) {
                    changed = true
                } else if ( oldDictionary[key] == nil ) {
                    changed = true
                } else {
                    if let newValue = value as AnyObject?, let oldValue = oldDictionary[key] as AnyObject? {
                        changed = !newValue.isEqual(oldValue)
                    }
                }
            } else {
                changed = highlightChanges
            }

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isUserInteractionEnabled = true
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
            if (changed) {
                valueWrapper.backgroundColor = UIColor.systemYellow
            }

            if (value is NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else if (value is NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                valueField.isUserInteractionEnabled = true
                valueField.isUserInteractionEnabled = true
                valueField.isEditable = false
                valueField.isSelectable = true
                valueField.isScrollEnabled = false
                valueField.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
                //valueField.backgroundColor = UIColor.systemPink
                if (changed) {
                    valueField.backgroundColor = UIColor.systemYellow
                }
                
                if (value is NSAttributedString) {
                    valueField.attributedText = value as? NSAttributedString
                } else if (value is NSString) {
                    valueField.text = value as? String
                } else if (value is NSNumber) {
                    valueField.text = String(describing: value as! NSNumber)
                } else {
                    os_log("Unsupported data type for entry", log: OSLog.general, type: .error)
                }
                var baselineShift:CGFloat = 0.0
                if let valueFont = valueField.font {
                    baselineShift = (label.font.ascender - valueFont.ascender)
                }
                valueField.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
                valueField.textContainer.lineFragmentPadding = 0.0
                valueField.textColor = UIColor.label

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
            // Constrain to external view
            if constrainValueFieldWidthToView != nil {
                let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .width, relatedBy: .equal, toItem: constrainValueFieldWidthToView, attribute: .width, multiplier: 1.0, constant: 0)
                rootView.addConstraint(valueWidthConstraint)
            }
        }
        
        if let selfAsScrollView = self as? UIScrollView {
            verticalStackView.layoutIfNeeded()
            selfAsScrollView.contentSize = verticalStackView.bounds.size
        }
    }


    func addArrayAsVerticalStack(_ array: NSArray, horisontalHuggingForLabel:UILayoutPriority, verticalHuggingForLabel:UILayoutPriority, horisontalHuggingForValue:UILayoutPriority, verticalHuggingForValue:UILayoutPriority, constrainValueFieldWidthToView: UIView?) {

        if array.count < 1 {
            // Array empty, returning
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
            if (value is NSNull) {
                // Empty element - ignore
                continue
            }
            
            // Set up text wrapper
            let valueWrapper = UIView()
            valueWrapper.translatesAutoresizingMaskIntoConstraints = false
            valueWrapper.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
            valueWrapper.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
            
            if (value is NSArray) {
                // Handle arrays
                valueWrapper.addArrayAsVerticalStack(value as! NSArray, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else if (value is NSDictionary) {
                // Handle dictionary
                valueWrapper.addDictionaryAsGrid(value as! NSDictionary, horisontalHuggingForLabel: horisontalHuggingForLabel, verticalHuggingForLabel: verticalHuggingForLabel, horisontalHuggingForValue: horisontalHuggingForValue, verticalHuggingForValue: verticalHuggingForValue, constrainValueFieldWidthToView: nil)
            } else {
                // UITextView
                let valueField = UITextView()
                valueField.translatesAutoresizingMaskIntoConstraints = false
                valueField.isUserInteractionEnabled = true
                valueField.isEditable = false
                valueField.isSelectable = true
                valueField.isScrollEnabled = false
                valueField.textContainerInset = UIEdgeInsets.zero
                valueField.textContainer.lineFragmentPadding = 0.0
                valueField.setContentHuggingPriority(horisontalHuggingForValue, for: .horizontal)
                valueField.setContentHuggingPriority(verticalHuggingForValue, for: .vertical)
                if (value is NSString) {
                    valueField.text = value as? String
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
            // Constrain to external view
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
            let colors = [UIColor.yellow, UIColor.lightGray, UIColor.blue, UIColor.brown, UIColor.gray, UIColor.green, UIColor.magenta]
            if level < colors.count {
                view.backgroundColor = colors[level]
            } else {
                view.backgroundColor = UIColor.red
            }
        })
    }

}
