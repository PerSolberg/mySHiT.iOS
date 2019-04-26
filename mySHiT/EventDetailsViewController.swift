//
//  EventDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-01-23.
//  Copyright © 2017 &More AS. All rights reserved.
//

//import Foundation

import UIKit

class EventDetailsViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var venueNameTextField: UITextField!
    @IBOutlet weak var venueAddressTextView: UITextView!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var travelTimeTextField: UITextField!
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var venuePhoneTextField: UITextField!
    @IBOutlet weak var accessInfoTextView: UITextView!
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Section data
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
//        print("Event Details Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
//        print("Event Details View loaded")
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HotelDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "RefreshTripElements"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HotelDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "dataRefreshed"), object: nil)
        
        // Adjust text views to align them with text fields
        venueAddressTextView.textContainerInset = UIEdgeInsets.zero
        venueAddressTextView.textContainer.lineFragmentPadding = 0.0
        accessInfoTextView.textContainerInset = UIEdgeInsets.zero
        accessInfoTextView.textContainer.lineFragmentPadding = 0.0
        
        if let eventElement = tripElement?.tripElement as? Event {
            var fullAddress:String = eventElement.venueAddress ?? ""
            switch (eventElement.venuePostCode ?? "", eventElement.venueCity ?? "") {
            case ("", ""):
                break
            case ("", _):
                fullAddress += "\n" + eventElement.venueCity!
            case (_, ""):
                fullAddress += "\n" + eventElement.venuePostCode!
            default:
                fullAddress += "\n" + eventElement.venuePostCode! + " " + eventElement.venueCity!
            }
            venueNameTextField.text = eventElement.venueName
            venueAddressTextView.text = fullAddress
            startTimeTextField.text = eventElement.startTime(dateStyle: .none, timeStyle: .short)
            travelTimeTextField.text = eventElement.travelTimeInfo
            
            if let refList = eventElement.references {
                let references = NSMutableString()
                var separator = ""
                for ref in refList {
                    if let refType = ref["type"], let refNo   = ref["refNo"] {
                        print("Reference: Type = \(refType), Ref # = \(refNo)")
                        references.append(separator + refNo)
                        separator = ", "
                    }
                }
                referenceTextField.text = references as String
            }
            venuePhoneTextField.text = eventElement.venuePhone
            accessInfoTextView.text = eventElement.accessInfo
        } else {
            venueNameTextField.text = "Unknown"
            venueAddressTextView.text = "Don't know where"
            startTimeTextField.text = "Don't know when"
            travelTimeTextField.text = "We'll leave again"
            referenceTextField.text = "Vera Lynn"
            venuePhoneTextField.text = "+1 (555) 123-4567"
            accessInfoTextView.text = "Please see your welcome leaflet."
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
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

    @objc override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? EventDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }
}

