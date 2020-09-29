//
//  FlightDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-30.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class FlightDetailsViewController: TripElementViewController, UITextViewDelegate, UIScrollViewDelegate {
    //
    // MARK: Properties
    //
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
        
    
    //
    // MARK: Navigation
    //
    
    
    //
    // MARK: Constructors
    //
    
    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0

        departureLocationTextView.isScrollEnabled = false
        departureLocationTextView.textContainerInset = UIEdgeInsets.zero
        departureLocationTextView.textContainer.lineFragmentPadding = 0.0
        arrivalLocationTextView.isScrollEnabled = false
        arrivalLocationTextView.textContainerInset = UIEdgeInsets.zero
        arrivalLocationTextView.textContainer.lineFragmentPadding = 0.0

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.dataRefreshed, object: nil)
        
        //self.view.colourSubviews()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        populateScreen(detectChanges: false, oldElement: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: mainStackView.frame.width, height: mainStackView.frame.height)
    }
    
    
    //
    // MARK: UITextViewDelegate
    //


    //
    // MARK: Actions
    //
    
    
    //
    // MARK: Functions
    ///
    func populateScreen(detectChanges: Bool, oldElement:Flight?) {
        guard let flightElement = tripElement as? Flight else {
            showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.unableToDisplayElement, completion: nil)
            
            self.navigationController?.popViewController(animated: true)
            return
        }

        flightNoTextField.setText(flightElement.routeName, detectChanges: detectChanges)
        airlineTextField.setText(flightElement.companyName, detectChanges: detectChanges)
        departureTimeTextField.setText(flightElement.startTime(dateStyle: .medium, timeStyle: .short), detectChanges: detectChanges)
        let departureInfo = buildLocationInfo(stopName: flightElement.departureStop, location: flightElement.departureLocation, terminalName: flightElement.departureTerminalName, address: flightElement.departureAddress)
        let attrDepartureInfo = NSMutableAttributedString(string: departureInfo)
        attrDepartureInfo.setAttributes([.font : departureLocationTextView.font as Any])
        attrDepartureInfo.addLink(for: Constant.RegEx.matchAll, transform: Address.getMapLink(_:))
        departureLocationTextView.setText(attrDepartureInfo, detectChanges: detectChanges)
        
        arrivalTimeTextField.setText(flightElement.endTime(dateStyle: .medium, timeStyle: .short), detectChanges: detectChanges)
        let arrivalInfo = buildLocationInfo(stopName: flightElement.arrivalStop, location: flightElement.arrivalLocation, terminalName: flightElement.arrivalTerminalName, address: flightElement.arrivalAddress)
        let attrArrivalInfo = NSMutableAttributedString(string: arrivalInfo)
        attrArrivalInfo.setAttributes([.font : arrivalLocationTextView.font as Any])
        attrArrivalInfo.addLink(for: Constant.RegEx.matchAll, transform: Address.getMapLink(_:))
        arrivalLocationTextView.setText(attrArrivalInfo, detectChanges: detectChanges)
        
        if let refList = flightElement.references {
            let horisontalHuggingLabel = flightNoLabel.contentHuggingPriority(for: .horizontal)
            let horisontalHuggingValue = departureLocationTextView.contentHuggingPriority(for: .horizontal)
            let verticalHuggingLabel = flightNoLabel.contentHuggingPriority(for: .vertical)
            let verticalHuggingValue = departureLocationTextView.contentHuggingPriority(for: .vertical)

            var oldReferences:NSDictionary? = nil
            let refDict = getAttributedReferences(refList, typeKey: TripElement.RefTag_Type, refKey: TripElement.RefTag_RefNo, urlKey: TripElement.RefTag_LookupURL)
            if let oldFlight = oldElement, let oldRefs = oldFlight.references {
                oldReferences = getAttributedReferences(oldRefs, typeKey: TripElement.RefTag_Type, refKey: TripElement.RefTag_RefNo, urlKey: TripElement.RefTag_LookupURL)
            }
            referencesView.addDictionaryAsGrid(refDict, oldDictionary: oldReferences, horisontalHuggingForLabel: horisontalHuggingLabel, verticalHuggingForLabel: verticalHuggingLabel, horisontalHuggingForValue: horisontalHuggingValue, verticalHuggingForValue: verticalHuggingValue, constrainValueFieldWidthToView: flightNoTextField, highlightChanges: detectChanges)
        }
    }
    
    
    func buildLocationInfo(stopName: String?, location: String?, terminalName: String?, address: String?) -> String {
        var locationInfo = stopName ?? location ?? ""
        if let terminal = terminalName {
            locationInfo += (terminal == "" ? "" : Constant.lineFeed + terminal)
        }
        if let address = address {
            locationInfo += (address == "" ? "" : Constant.lineFeed + address)
        }
        return locationInfo
    }

    
    @objc func refreshTripElements() {
        DispatchQueue.main.async(execute: {
            if let flightElement = self.tripElement as? Flight {
                guard let (_, aElement) = TripList.sharedList.tripElement(byId: flightElement.id) else {
                    // Couldn't find trip element, trip or element deleted
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                
                self.tripElement = aElement.tripElement
                self.populateScreen(detectChanges: true, oldElement: flightElement)
            }
        })
    }
    
    
    override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? FlightDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.id == vcte.id
        } else {
            return false
        }
    }
    
    
    //
    // MARK: ScrollViewDelegate
    //
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainStackView
    }
}

