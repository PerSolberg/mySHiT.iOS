//
//  ScheduledTransportDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-04.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class ScheduledTransportDetailsViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, DeepLinkableViewController {
    
    // MARK: Properties
    @IBOutlet weak var rootScrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
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
    
    // DeepLinkableViewController
    var wasDeepLinked = false
    
    // MARK: Navigation
    
    // MARK: Constructors
    
    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        rootScrollView.minimumZoomScale = 1.0
        rootScrollView.maximumZoomScale = 2.0
       
        departureInfoTextView.textContainerInset = UIEdgeInsets.zero
        departureInfoTextView.textContainer.lineFragmentPadding = 0.0
        arrivalInfoTextView.textContainerInset = UIEdgeInsets.zero
        arrivalInfoTextView.textContainer.lineFragmentPadding = 0.0

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.dataRefreshed, object: nil)        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.populateScreen(detectChanges: false, oldElement: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }



    //
    // MARK: UITextViewDelegate
    //
    
    
    //
    // MARK: ScrollViewDelegate
    //
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }


    //
    // MARK: Actions
    //
    
    
    //
    // MARK: Functions
    //
    func populateScreen(detectChanges: Bool, oldElement: ScheduledTransport?) {
        guard let transportElement = tripElement?.tripElement as? ScheduledTransport else {
            showAlert(title: Constant.msg.alertBoxTitle, message: Constant.msg.unableToDisplayElement, completion: nil)
            
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        companyTextField.text = transportElement.companyName
        routeNoTextField.text = transportElement.routeNo
        
        departureTimeTextField.text = transportElement.startTime(dateStyle: .medium, timeStyle: .short)
        let departureInfo = buildLocationInfo(stopName: transportElement.departureStop, location: transportElement.departureLocation, terminalName: transportElement.departureTerminalName, address: transportElement.departureAddress)
        let attrDepartureInfo = NSMutableAttributedString(string: departureInfo)
        attrDepartureInfo.setAttributes([.font : departureInfoTextView.font as Any])
        attrDepartureInfo.addLink(for: ".+", options: [.dotMatchesLineSeparators], transform: Address.getMapLink(_:))
        departureInfoTextView.setText(attrDepartureInfo, detectChanges: detectChanges)
        
        arrivalTimeTextField.text = transportElement.endTime(dateStyle: .medium, timeStyle: .short)
        let arrivalInfo = buildLocationInfo(stopName: transportElement.arrivalStop, location: transportElement.arrivalLocation, terminalName: transportElement.arrivalTerminalName, address: transportElement.arrivalAddress)
        let attrArrivalInfo = NSMutableAttributedString(string: arrivalInfo)
        attrArrivalInfo.setAttributes([.font : arrivalInfoTextView.font as Any])
        attrArrivalInfo.addLink(for: ".+", options: [.dotMatchesLineSeparators], transform: Address.getMapLink(_:))
        arrivalInfoTextView.setText(attrArrivalInfo, detectChanges: detectChanges)
        //referenceTextView.text = "references go here"
    }

    
    func buildLocationInfo(stopName: String?, location: String?, terminalName: String?, address: String?) -> String {
        var locationInfo = stopName ?? location ?? ""
        if let terminal = terminalName, terminal != "" {
            locationInfo += ("\n" + terminal)
        }
        if let address = address, address != "" {
            locationInfo += ("\n" + address)
        }
        if let _ = stopName, let location = location {
            locationInfo += ("\n" + location)
        }

        return locationInfo
    }


    @objc func refreshTripElements() {
        DispatchQueue.main.async(execute: {
            if let transportElement = self.tripElement?.tripElement as? ScheduledTransport {
                guard let (aTrip, aElement) = TripList.sharedList.tripElement(byId: transportElement.id) else {
                    // Couldn't find trip element, trip or element deleted
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                
                self.trip = aTrip
                self.tripElement = aElement
                self.populateScreen(detectChanges: true, oldElement: transportElement)
            }
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

