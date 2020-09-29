//
//  EventDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-01-23.
//  Copyright © 2017 &More AS. All rights reserved.
//

//import Foundation

import UIKit

class EventDetailsViewController: TripElementViewController, UIScrollViewDelegate {
    //
    // MARK: Properties
    //
    @IBOutlet weak var rootScrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var venueNameTextField: UITextField!
    @IBOutlet weak var venueAddressTextView: UITextView!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var travelTimeTextField: UITextField!
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var venuePhoneLabel: UILabel!
    @IBOutlet weak var venuePhoneText: UITextView!
    @IBOutlet weak var accessInfoTextView: UITextView!


    
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
        rootScrollView.minimumZoomScale = 1.0
        rootScrollView.maximumZoomScale = 2.0
        
        // Adjust text views to align them with text fields
        venueAddressTextView.textContainerInset = UIEdgeInsets.zero
        venueAddressTextView.textContainer.lineFragmentPadding = 0.0
        accessInfoTextView.textContainerInset = UIEdgeInsets.zero
        accessInfoTextView.textContainer.lineFragmentPadding = 0.0
        venuePhoneText.alignBaseline(to: venuePhoneLabel)
        venuePhoneText.textContainer.lineFragmentPadding = 0.0
        venuePhoneText.isScrollEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.dataRefreshed, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        populateScreen(detectChanges: false)
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    
    //
    // MARK: Actions
    //
    
    
    //
    // MARK: Functions
    //
    func populateScreen(detectChanges: Bool) {
        if let eventElement = tripElement as? Event {
            var fullAddress:String = eventElement.venueAddress ?? ""
            switch (eventElement.venuePostCode ?? "", eventElement.venueCity ?? "") {
            case ("", ""):
                break
            case ("", _):
                fullAddress += Constant.lineFeed + eventElement.venueCity!
            case (_, ""):
                fullAddress += Constant.lineFeed + eventElement.venuePostCode!
            default:
                fullAddress += Constant.lineFeed + String.localizedStringWithFormat(Address.Format.postCodeAndCity, eventElement.venuePostCode!, eventElement.venueCity!)
            }
            venueNameTextField.setText(eventElement.venueName, detectChanges: detectChanges)
            let attrAddress = NSMutableAttributedString(string: fullAddress)
            attrAddress.setAttributes([.font : venueAddressTextView.font as Any])
            attrAddress.addLink(for: Constant.RegEx.matchAll, transform: Address.getMapLink(_:))
            venueAddressTextView.setText(attrAddress, detectChanges: detectChanges)
            startTimeTextField.setText(eventElement.startTime(dateStyle: .none, timeStyle: .short), detectChanges: detectChanges)
            travelTimeTextField.setText(eventElement.travelTimeInfo, detectChanges: detectChanges)

            referenceTextField.setText(eventElement.referenceList(separator: TripElement.Format.refListSeparator), detectChanges: detectChanges)
            venuePhoneText.setText(eventElement.venuePhone, detectChanges: detectChanges)
            accessInfoTextView.setText(eventElement.accessInfo, detectChanges: detectChanges)
        } else {
            showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.unableToDisplayElement, completion: nil)

            self.navigationController?.popViewController(animated: true)
        }
    }

    
    @objc func refreshTripElements() {
        DispatchQueue.main.async(execute: {
            if let eventElement = self.tripElement as? Event {
                guard let (_, aElement) = TripList.sharedList.tripElement(byId: eventElement.id) else {
                    // Couldn't find trip element, trip or element deleted
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                
                self.tripElement = aElement.tripElement
                self.populateScreen(detectChanges: true)
            }
        })
    }

    
    @objc override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? EventDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.id == vcte.id
        } else {
            return false
        }
    }

    
    //
    // MARK: ScrollViewDelegate
    //
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

