//
//  FlightDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-30.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class FlightDetailsViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var flightNoLabel: UILabel!
    @IBOutlet weak var flightNoTextField: UITextField!
    @IBOutlet weak var departureTimeTextField: UITextField!
    @IBOutlet weak var departureLocationTextView: UITextView!
    @IBOutlet weak var arrivalTimeTextField: UITextField!
    @IBOutlet weak var arrivalLocationTextView: UITextView!
    @IBOutlet weak var referencesView: UIView!
    //@IBOutlet weak var referencesView: UIView!
    //@IBOutlet weak var referencesView: UIScrollView!
    //@IBOutlet weak var mainStackView: UIStackView!

    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Section data
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        print("Flight Details: Preparing for segue '\(segue.identifier)'")
    }
    

    // MARK: Constructors
    required init?(coder: NSCoder) {
    super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Flight Details View loaded")
        super.viewDidLoad()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "RefreshTripElements", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "dataRefreshed", object: nil)

        departureLocationTextView.scrollEnabled = false
        arrivalLocationTextView.scrollEnabled = false
        
        if let flightElement = tripElement?.tripElement as? Flight {
            flightNoTextField.text = (flightElement.airlineCode ?? "XX") + " " + (flightElement.routeNo ?? "***")
            departureTimeTextField.text = flightElement.startTime(dateStyle: .MediumStyle, timeStyle: .ShortStyle)
            var locationInfo = flightElement.departureStop ?? flightElement.departureLocation ?? ""
            if let departureTerminal = flightElement.departureTerminalName {
                locationInfo += (departureTerminal == "" ? "" : "\n" + departureTerminal)
            }
            if let departureAddress = flightElement.departureAddress {
                locationInfo += (departureAddress == "" ? "" : "\n" + departureAddress)
            }
            departureLocationTextView.text = locationInfo
            departureLocationTextView.textContainerInset = UIEdgeInsetsZero
            departureLocationTextView.textContainer.lineFragmentPadding = 0.0

            arrivalTimeTextField.text = flightElement.endTime(dateStyle: .MediumStyle, timeStyle: .ShortStyle)
            locationInfo = flightElement.arrivalStop ?? flightElement.arrivalLocation ?? ""
            if let arrivalTerminal = flightElement.arrivalTerminalName {
                locationInfo += (arrivalTerminal == "" ? "" : "\n" + arrivalTerminal)
            }
            if let arrivalAddress = flightElement.arrivalAddress {
                locationInfo += (arrivalAddress == "" ? "" : "\n" + arrivalAddress)
            }
            arrivalLocationTextView.text = locationInfo
            arrivalLocationTextView.textContainerInset = UIEdgeInsetsZero
            arrivalLocationTextView.textContainer.lineFragmentPadding = 0.0
            
            if let refList = flightElement.references {
                /*
                // Set up vertical stack view and add it to main view
                let verticalStackView = UIStackView()
                verticalStackView.axis = .Vertical
                verticalStackView.distribution = .Fill
                verticalStackView.alignment = .Fill
                verticalStackView.spacing = 8;
                verticalStackView.translatesAutoresizingMaskIntoConstraints = false
                referencesView.addSubview(verticalStackView)

                // Constrain vertical stack view to (scrollable) view
                referencesView.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Leading, relatedBy: .Equal, toItem: referencesView, attribute: .Leading, multiplier: 1.0, constant: 0.0))
                referencesView.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Trailing , relatedBy: .Equal, toItem: referencesView, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
                referencesView.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: .Top, relatedBy: .Equal, toItem: referencesView, attribute: .Top, multiplier: 1.0, constant: 0.0))
                // */
                
                let horisontalHuggingLabel = flightNoLabel.contentHuggingPriorityForAxis(.Horizontal)
                let horisontalHuggingValue = departureLocationTextView.contentHuggingPriorityForAxis(.Horizontal)
                let verticalHuggingLabel = flightNoLabel.contentHuggingPriorityForAxis(.Vertical)
                let verticalHuggingValue = departureLocationTextView.contentHuggingPriorityForAxis(.Vertical)
                print("Hugging: Label(V) = \(verticalHuggingLabel), Label(H) = \(horisontalHuggingLabel), Value(V) = \(verticalHuggingValue), Value(H) = \(horisontalHuggingValue)")
                let refDict = NSMutableDictionary()
                for ref in refList {
                    if let refType = ref["type"], refNo = ref["refNo"] {
                        var refText:NSAttributedString?
                        if let refUrl = ref["urlLookup"], url = NSURL(string: refUrl) {
                            let hyperlinkText = NSMutableAttributedString(string: refNo)
                            hyperlinkText.addAttribute(NSLinkAttributeName, value: url, range: NSMakeRange(0, hyperlinkText.length))
                            refText = hyperlinkText
                        } else {
                            refText = NSAttributedString(string:refNo)
                        }
                        //refDict.setValue(refText, forKey: refType)
                        refDict[refType] = refText
                    }
                }
                referencesView.addDictionaryAsGrid(refDict, horisontalHuggingForLabel: horisontalHuggingLabel, verticalHuggingForLabel: verticalHuggingLabel, horisontalHuggingForValue: horisontalHuggingValue, verticalHuggingForValue: verticalHuggingValue, constrainValueFieldWidthToView: flightNoTextField)
                
                /*
                for ref in refList {
                    if let refType = ref["type"], refNo   = ref["refNo"] {
                        print("Reference: Type = \(refType), Ref # = \(refNo)")
                        let label = UILabel()
                        label.translatesAutoresizingMaskIntoConstraints = false
                        label.font = flightNoTextField.font //flightNoLabel.font
                        label.userInteractionEnabled = false
                        label.setContentHuggingPriority(horisontalHuggingLabel, forAxis: .Horizontal)
                        label.setContentHuggingPriority(verticalHuggingLabel, forAxis: .Vertical)
                        label.text = refType
                        label.invalidateIntrinsicContentSize()
                        
                        // UITextView
                        let value = UITextView()
                        value.translatesAutoresizingMaskIntoConstraints = false
                        value.font = flightNoTextField.font
                        value.userInteractionEnabled = true
                        value.editable = false
                        value.selectable = true
                        value.scrollEnabled = false
                        value.textContainerInset = UIEdgeInsetsZero
                        value.textContainer.lineFragmentPadding = 0.0
                        value.setContentHuggingPriority(horisontalHuggingValue, forAxis: .Horizontal)
                        value.setContentHuggingPriority(verticalHuggingValue, forAxis: .Vertical)
                        
                        if let refUrl = ref["urlLookup"], url = NSURL(string: refUrl) {
                            let hyperlinkText = NSMutableAttributedString(string: refNo)
                            hyperlinkText.addAttribute(NSLinkAttributeName, value: url, range: NSMakeRange(0, hyperlinkText.length))
                            value.attributedText = hyperlinkText
                        } else {
                            value.text = refNo
                        }
                        value.invalidateIntrinsicContentSize()
                        
                        // Set up text wrapper
                        let valueWrapper = UIView()
                        valueWrapper.translatesAutoresizingMaskIntoConstraints = false
                        valueWrapper.setContentHuggingPriority(horisontalHuggingValue, forAxis: .Horizontal)
                        valueWrapper.setContentHuggingPriority(verticalHuggingValue, forAxis: .Vertical)
                        valueWrapper.addSubview(value)
                        valueWrapper.addConstraint(NSLayoutConstraint(item: value, attribute: .Leading, relatedBy: .Equal, toItem: valueWrapper, attribute: .Leading, multiplier: 1.0, constant: 0.0))
                        valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Trailing , relatedBy: .Equal, toItem: value, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
                        valueWrapper.addConstraint(NSLayoutConstraint(item: value, attribute: .Top, relatedBy: .Equal, toItem: valueWrapper, attribute: .Top, multiplier: 1.0, constant: 0.0))
                        valueWrapper.addConstraint(NSLayoutConstraint(item: valueWrapper, attribute: .Bottom, relatedBy: .Equal, toItem: value, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
                        
                        let horisontalStackView = UIStackView(arrangedSubviews: [label , valueWrapper])
                        horisontalStackView.axis = .Horizontal
                        horisontalStackView.distribution = .Fill
                        horisontalStackView.alignment = .Fill // .FirstBaseline
                        horisontalStackView.spacing = 8;
                        horisontalStackView.translatesAutoresizingMaskIntoConstraints = false
                        
                        verticalStackView.addArrangedSubview(horisontalStackView)

                        // Constrain to flight info
                        let valueWidthConstraint = NSLayoutConstraint(item: valueWrapper, attribute: .Width, relatedBy: .Equal, toItem: flightNoTextField, attribute: .Width, multiplier: 1.0, constant: 0)
                        mainStackView.addConstraint(valueWidthConstraint)
                    }
                }
                // */
            }
        } else {
            flightNoTextField.text = "XX 0000"
            departureTimeTextField.text = "##. xxx. #### ##:##"
            departureLocationTextView.text = "<Missing info>"
            arrivalTimeTextField.text = "##. xxx. #### ##:##"
            arrivalLocationTextView.text = "<Missing info>"
        }

        self.view.colourSubviews()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: mainStackView.frame.width, height: mainStackView.frame.height)
    }
    
    // MARK: UITextViewDelegate


    // MARK: Actions
    
    
    // MARK: Functions
    func refreshTripElements() {
        print("Refreshing trip details - probably because data were refreshed")
        //updateSections()
        dispatch_async(dispatch_get_main_queue(), {
            //self.title = self.trip?.trip.name
            //self.tripDetailsTable.reloadData()
        })
    }
    
}

