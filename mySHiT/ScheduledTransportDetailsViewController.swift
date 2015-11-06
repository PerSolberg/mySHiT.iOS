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
    @IBOutlet weak var departureInfoTextView: UITextView!
    @IBOutlet weak var arrivalInfoTextView: UITextView!
    @IBOutlet weak var referenceView: UIView!

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
        print("Scheduled Transport Details View loaded")
        super.viewDidLoad()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "RefreshTripElements", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "dataRefreshed", object: nil)
        
        //departureLocationTextView.scrollEnabled = false
        //arrivalLocationTextView.scrollEnabled = false
        
        if let transportElement = tripElement?.tripElement as? GenericTransport {
            print(transportElement.routeNo)
            companyTextField.text = transportElement.companyName
            routeNoTextField.text = transportElement.routeNo
            departureInfoTextView.text = transportElement.departureLocation
            arrivalInfoTextView.text = transportElement.arrivalLocation
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
        dispatch_async(dispatch_get_main_queue(), {
            //self.title = self.trip?.trip.name
            //self.tripDetailsTable.reloadData()
        })
    }
    
}

