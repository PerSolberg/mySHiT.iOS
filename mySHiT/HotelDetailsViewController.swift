//
//  HotelDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-30.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class HotelDetailsViewController: TripElementViewController, UIScrollViewDelegate {
    
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
    
    // MARK: Navigation
    
    // MARK: Constructors
    
    
    //
    // MARK: Callbacks
    //
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

        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.dataRefreshed, object: nil)
        
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
        guard let hotelElement = tripElement as? Hotel else {
            showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.unableToDisplayElement, completion: nil)

            self.navigationController?.popViewController(animated: true)
            return
        }
        
        var fullAddress:String = hotelElement.address ?? ""
        switch (hotelElement.postCode ?? "", hotelElement.city ?? "") {
        case ("", ""):
            break
        case ("", _):
            fullAddress += Constant.lineFeed + hotelElement.city!
        case (_, ""):
            fullAddress += Constant.lineFeed + hotelElement.postCode!
        default:
            fullAddress += Constant.lineFeed + String.localizedStringWithFormat(Address.Format.postCodeAndCity, hotelElement.postCode!, hotelElement.city!)
                // hotelElement.postCode! + " " + hotelElement.city!
        }
        hotelNameTextField.setText(hotelElement.hotelName, detectChanges: detectChanges)
        let attrAddress = NSMutableAttributedString(string: fullAddress)
        attrAddress.setAttributes([.font : hotelAddressTextView.font as Any])
        attrAddress.addLink(for: Constant.RegEx.matchAll, transform: Address.getMapLink(_:))
        hotelAddressTextView.setText(attrAddress, detectChanges: detectChanges)
        checkInTextField.setText(hotelElement.startTime(dateStyle: .medium, timeStyle: .none), detectChanges: detectChanges)
        checkOutTextField.setText(hotelElement.endTime(dateStyle: .medium, timeStyle: .none), detectChanges: detectChanges)
        referenceTextField.setText(hotelElement.referenceList(separator: TripElement.Format.refListSeparator), detectChanges: detectChanges)
        phoneTextView.setText(hotelElement.phone, detectChanges: detectChanges)
        //transferInfoTextView.setText("Please see your welcome leaflet.", detectChanges: detectChanges)
        transferInfoTextView.setText(Constant.Message.hotelTransferInfoDefault, detectChanges: detectChanges)
    }

    
    @objc func refreshTripElements() {
        DispatchQueue.main.async(execute: {
            if let eventElement = self.tripElement as? Hotel {
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
        } else if let vc = vc as? HotelDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
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

