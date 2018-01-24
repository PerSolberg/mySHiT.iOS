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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        print("Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Hotel Details View loaded")
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HotelDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "RefreshTripElements"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HotelDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "dataRefreshed"), object: nil)
        
        // Adjust text views to align them with text fields
        hotelAddressTextView.textContainerInset = UIEdgeInsets.zero
        hotelAddressTextView.textContainer.lineFragmentPadding = 0.0
        transferInfoTextView.textContainerInset = UIEdgeInsets.zero
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
            checkInTextField.text = hotelElement.startTime(dateStyle: .medium, timeStyle: .none)
            checkOutTextField.text = hotelElement.endTime(dateStyle: .medium, timeStyle: .none)

            if let refList = hotelElement.references {
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
        DispatchQueue.main.async(execute: {
            //self.title = self.trip?.trip.name
            //self.tripDetailsTable.reloadData()
        })
    }
    
    override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? HotelDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }
}

