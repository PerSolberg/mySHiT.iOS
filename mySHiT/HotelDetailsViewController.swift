//
//  HotelDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-30.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class HotelDetailsViewController: UIViewController, UIScrollViewDelegate, DeepLinkableViewController {
    
    // MARK: Properties
    @IBOutlet weak var rootScrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var hotelNameTextField: UITextField!
    @IBOutlet weak var hotelAddressTextView: UITextView!
    @IBOutlet weak var checkInTextField: UITextField!
    @IBOutlet weak var checkOutTextField: UITextField!
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var transferInfoTextView: UITextView!
    
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // DeepLinkableViewController
    var wasDeepLinked = false
    
    // MARK: Navigation
    
    // MARK: Constructors
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        rootScrollView.minimumZoomScale = 1.0
        rootScrollView.maximumZoomScale = 2.0

        // Adjust text views to align them with text fields
        hotelAddressTextView.textContainerInset = UIEdgeInsets.zero
        hotelAddressTextView.textContainer.lineFragmentPadding = 0.0
        transferInfoTextView.textContainerInset = UIEdgeInsets.zero
        transferInfoTextView.textContainer.lineFragmentPadding = 0.0
        phoneTextView.alignBaseline(to: phoneLabel)
        phoneTextView.textContainer.lineFragmentPadding = 0.0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.dataRefreshed, object: nil)
        
        populateScreen(detectChanges: false)
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func populateScreen(detectChanges: Bool) {
        guard let hotelElement = tripElement?.tripElement as? Hotel else {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: Constant.dummyLocalisationComment),
                    message: NSLocalizedString(Constant.msg.unableToDisplayElement, comment: Constant.dummyLocalisationComment),
                    preferredStyle: UIAlertController.Style.alert)
                alert.addAction(Constant.alert.actionOK)
                self.present(alert, animated: true, completion: { })
            })
            
            self.navigationController?.popViewController(animated: true)
            return
        }
        
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
        hotelNameTextField.setText(hotelElement.hotelName, detectChanges: detectChanges)
        let attrAddress = NSMutableAttributedString(string: fullAddress)
        attrAddress.setAttributes([.font : hotelAddressTextView.font as Any])
        attrAddress.addLink(for: ".+", options: [.dotMatchesLineSeparators], transform: Address.getMapLink(_:))
        hotelAddressTextView.setText(attrAddress, detectChanges: detectChanges)
        checkInTextField.setText(hotelElement.startTime(dateStyle: .medium, timeStyle: .none), detectChanges: detectChanges)
        checkOutTextField.setText(hotelElement.endTime(dateStyle: .medium, timeStyle: .none), detectChanges: detectChanges)
        
        if let refList = hotelElement.references {
            let references = NSMutableString()
            var separator = ""
            for ref in refList {
                if /*let refType = ref["type"], */let refNo   = ref["refNo"] {
                    //print("Reference: Type = \(refType), Ref # = \(refNo)")
                    references.append(separator + refNo)
                    separator = ", "
                }
            }
            referenceTextField.setText(references as String, detectChanges: detectChanges)
        }
        phoneTextView.setText(hotelElement.phone, detectChanges: detectChanges)
        transferInfoTextView.setText("Please see your welcome leaflet.", detectChanges: detectChanges)
    }

    
    @objc func refreshTripElements() {
        DispatchQueue.main.async(execute: {
            if let eventElement = self.tripElement?.tripElement as? Hotel {
                guard let (aTrip, aElement) = TripList.sharedList.tripElement(byId: eventElement.id) else {
                    // Couldn't find trip element, trip or element deleted
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                
                self.trip = aTrip
                self.tripElement = aElement
                self.populateScreen(detectChanges: true)
            }
        })
    }
    
    @objc override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? HotelDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }

    
    // MARK: ScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

