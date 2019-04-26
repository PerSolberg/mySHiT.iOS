//
//  PrivateTransportDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class PrivateTransportDetailsViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var departureLabel: UILabel!
    @IBOutlet weak var departureTextView: UITextView!
    @IBOutlet weak var arrivalLabel: UILabel!
    @IBOutlet weak var arrivalTextView: UITextView!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var referencesView: UIView!
    
    // MARK: Properties
    
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Section data
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
//        print("Private Transport Details: Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
//        print("Private Transport Details View loaded")
        super.viewDidLoad()
        
        if let transportElement = tripElement?.tripElement as? GenericTransport {
            companyTextField.text = transportElement.companyName ?? "<Unknown company>"
            
            var locationInfo = transportElement.departureStop ?? ""
            if let departureTerminal = transportElement.departureTerminalName {
                locationInfo += (departureTerminal == "" ? "" : "\n" + departureTerminal)
            }
            if let departureAddress = transportElement.departureAddress {
                locationInfo += (departureAddress == "" ? "" : "\n" + departureAddress)
            }
            if let departureLocation = transportElement.departureLocation {
                locationInfo += (departureLocation == "" ? "" : "\n" + departureLocation)
            }
            departureTextView.text = locationInfo

            locationInfo = transportElement.arrivalStop ?? transportElement.arrivalLocation ?? ""
            if let arrivalTerminal = transportElement.arrivalTerminalName {
                locationInfo += (arrivalTerminal == "" ? "" : "\n" + arrivalTerminal)
            }
            if let arrivalAddress = transportElement.arrivalAddress {
                locationInfo += (arrivalAddress == "" ? "" : "\n" + arrivalAddress)
            }
            if let arrivalLocation = transportElement.arrivalLocation {
                locationInfo += (arrivalLocation == "" ? "" : "\n" + arrivalLocation)
            }
            arrivalTextView.text = locationInfo
            phoneTextField.text = transportElement.companyPhone
            //referenceTextView.text = "references go here"

            // Adjust baselines on text views to label
            var baselineShift:CGFloat = 0.0
            if let valueFont = departureTextView.font {
                baselineShift = (departureLabel.font.ascender - valueFont.ascender)
            }
            departureTextView.isScrollEnabled = false
            departureTextView.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
            departureTextView.textContainer.lineFragmentPadding = 0.0
            
            baselineShift = 0.0
            if let valueFont = arrivalTextView.font {
                baselineShift = (arrivalLabel.font.ascender - valueFont.ascender)
            }
            arrivalTextView.isScrollEnabled = false
            arrivalTextView.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
            arrivalTextView.textContainer.lineFragmentPadding = 0.0
            
            // Add references
            if let refList = transportElement.references {
                let horisontalHuggingLabel = companyLabel.contentHuggingPriority(for: .horizontal)
                let horisontalHuggingValue = companyTextField.contentHuggingPriority(for: .horizontal)
                let verticalHuggingLabel = companyLabel.contentHuggingPriority(for: .vertical)
                let verticalHuggingValue = companyTextField.contentHuggingPriority(for: .vertical)
                print("Hugging: Label(V) = \(verticalHuggingLabel), Label(H) = \(horisontalHuggingLabel), Value(V) = \(verticalHuggingValue), Value(H) = \(horisontalHuggingValue)")
                let refDict = NSMutableDictionary()
                for ref in refList {
                    if let refType = ref["type"], let refNo = ref["refNo"] {
                        var refText:NSAttributedString?
                        if let refUrl = ref["urlLookup"], let url = URL(string: refUrl) {
                            let hyperlinkText = NSMutableAttributedString(string: refNo)
                            hyperlinkText.addAttribute(NSAttributedString.Key.link, value: url, range: NSMakeRange(0, hyperlinkText.length))
                            refText = hyperlinkText
                        } else {
                            refText = NSAttributedString(string:refNo)
                        }
                        //refDict.setValue(refText, forKey: refType)
                        refDict[refType] = refText
                    }
                }
                referencesView.addDictionaryAsGrid(refDict, horisontalHuggingForLabel: horisontalHuggingLabel, verticalHuggingForLabel: verticalHuggingLabel, horisontalHuggingForValue: horisontalHuggingValue, verticalHuggingForValue: verticalHuggingValue, constrainValueFieldWidthToView: nil /* companyTextField */)
            }
        } else {
            companyTextField.text = ""
            //routeNoTextField.text = ""
            departureTextView.text = ""
            arrivalTextView.text = ""
            phoneTextField.text = ""
            //referenceTextView.text = ""
        }
        
        //self.view.colourSubviews()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextViewDelegate
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func refreshTripElements() {
//        print("Refreshing trip details - probably because data were refreshed")
        //updateSections()
        DispatchQueue.main.async(execute: {
            //self.title = self.trip?.trip.name
            //self.tripDetailsTable.reloadData()
        })
    }
    
    override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? PrivateTransportDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }
}

