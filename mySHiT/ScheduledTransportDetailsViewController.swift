//
//  ScheduledTransportDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-04.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class ScheduledTransportDetailsViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var routeNoTextField: UITextField!
    @IBOutlet weak var departureTimeTextField: UITextField!
    @IBOutlet weak var departureInfoTextView: UITextView!
    @IBOutlet weak var arrivalTimeTextField: UITextField!
    @IBOutlet weak var arrivalInfoTextView: UITextView!
    @IBOutlet weak var referenceView: UIView!

    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Section data
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        print("Flight Details: Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Scheduled Transport Details View loaded")
        super.viewDidLoad()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "RefreshTripElements", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "dataRefreshed", object: nil)
        
        //departureLocationTextView.scrollEnabled = false
        //arrivalLocationTextView.scrollEnabled = false
        
        if let transportElement = tripElement?.tripElement as? GenericTransport {
            print(transportElement.routeNo as Any)
            companyTextField.text = transportElement.companyName
            routeNoTextField.text = transportElement.routeNo

            departureTimeTextField.text = transportElement.startTime(dateStyle: .medium, timeStyle: .short)

            var locationInfo = transportElement.departureStop ?? transportElement.departureLocation ?? ""
            if let departureTerminal = transportElement.departureTerminalName {
                locationInfo += (departureTerminal == "" ? "" : "\n" + departureTerminal)
            }
            if let departureAddress = transportElement.departureAddress {
                locationInfo += (departureAddress == "" ? "" : "\n" + departureAddress)
            }
            if let _ = transportElement.departureStop {
                locationInfo += "\n" + (transportElement.departureLocation ?? "")
            }
            departureInfoTextView.text = locationInfo //transportElement.departureLocation
            departureInfoTextView.textContainerInset = UIEdgeInsets.zero
            departureInfoTextView.textContainer.lineFragmentPadding = 0.0
            
            arrivalTimeTextField.text = transportElement.endTime(dateStyle: .medium, timeStyle: .short)
            locationInfo = transportElement.arrivalStop ?? transportElement.arrivalLocation ?? ""
            if let arrivalTerminal = transportElement.arrivalTerminalName {
                locationInfo += (arrivalTerminal == "" ? "" : "\n" + arrivalTerminal)
            }
            if let arrivalAddress = transportElement.arrivalAddress {
                locationInfo += (arrivalAddress == "" ? "" : "\n" + arrivalAddress)
            }
            if let _ = transportElement.arrivalStop {
                locationInfo += "\n" + (transportElement.arrivalLocation ?? "")
            }
            arrivalInfoTextView.text = locationInfo //transportElement.arrivalLocation
            arrivalInfoTextView.textContainerInset = UIEdgeInsets.zero
            arrivalInfoTextView.textContainer.lineFragmentPadding = 0.0
            //referenceTextView.text = "references go here"
        } else {
            companyTextField.text = ""
            routeNoTextField.text = ""
            departureInfoTextView.text = ""
            arrivalInfoTextView.text = ""
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
        } else if let vc = vc as? ScheduledTransportDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }
}

