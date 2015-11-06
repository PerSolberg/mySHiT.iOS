//
//  HotelDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-30.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class HotelDetailsViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var hotelNameTextField: UITextField!
    @IBOutlet weak var hotelAddressTextView: UITextView!
    @IBOutlet weak var checkInTextField: UITextField!
    @IBOutlet weak var checkOutTextField: UITextField!
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var transferInfoTextView: UITextView!
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Section data
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        print("Preparing for segue '\(segue.identifier)'")
    }
    
    
    // MARK: Constructors
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Hotel Details View loaded")
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "RefreshTripElements", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "dataRefreshed", object: nil)
        
        // Adjust text views to align them with text fields
        hotelAddressTextView.textContainerInset = UIEdgeInsetsZero
        hotelAddressTextView.textContainer.lineFragmentPadding = 0.0
        transferInfoTextView.textContainerInset = UIEdgeInsetsZero
        transferInfoTextView.textContainer.lineFragmentPadding = 0.0
    
        if let hotelElement = tripElement?.tripElement as? Hotel {
            var fullAddress:String = hotelElement.address ?? ""
            switch (hotelElement.postCode ?? "", hotelElement.city ?? "") {
            case ("", ""):
                break
            case ("", _):
                fullAddress += "\n" + hotelElement.city!
            case (_, ""):
                fullAddress += "\n" + hotelElement.postCode!
            default:
                fullAddress += "\n" + hotelElement.postCode! + " " + hotelElement.city!
            }
            hotelNameTextField.text = hotelElement.hotelName
            hotelAddressTextView.text = fullAddress
            checkInTextField.text = hotelElement.startTime(dateStyle: .MediumStyle, timeStyle: .NoStyle)
            checkOutTextField.text = hotelElement.endTime(dateStyle: .MediumStyle, timeStyle: .NoStyle)

            if let refList = hotelElement.references {
                let references = NSMutableString()
                var separator = ""
                for ref in refList {
                    if let refType = ref["type"], refNo   = ref["refNo"] {
                        print("Reference: Type = \(refType), Ref # = \(refNo)")
                        references.appendString(separator + refNo)
                        separator = ", "
                    }
                }
                referenceTextField.text = references as String
            }
            phoneTextView.text = hotelElement.phone
            transferInfoTextView.text = "Please see your welcome leaflet."
        } else {
            hotelNameTextField.text = "Unknown"
            hotelAddressTextView.text = "Don't know where"
            checkInTextField.text = "Don't know when"
            checkOutTextField.text = "We'll leave again"
            referenceTextField.text = "Vera Lynn"
            phoneTextView.text = "+1 (555) 123-4567"
            transferInfoTextView.text = "Please see your welcome leaflet."
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
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

