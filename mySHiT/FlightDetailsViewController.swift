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
    @IBOutlet weak var airlineTextField: UITextField!
    @IBOutlet weak var departureTimeTextField: UITextField!
    @IBOutlet weak var departureLocationTextView: UITextView!
    @IBOutlet weak var arrivalTimeTextField: UITextField!
    @IBOutlet weak var arrivalLocationTextView: UITextView!
    @IBOutlet weak var referencesView: UIView!

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
            airlineTextField.text = flightElement.companyName
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
            }
        } else {
            flightNoTextField.text = "XX 0000"
            departureTimeTextField.text = "##. xxx. #### ##:##"
            departureLocationTextView.text = "<Missing info>"
            arrivalTimeTextField.text = "##. xxx. #### ##:##"
            arrivalLocationTextView.text = "<Missing info>"
        }

        //self.view.colourSubviews()
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

