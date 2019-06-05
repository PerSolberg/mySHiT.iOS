//
//  PrivateTransportDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class PrivateTransportDetailsViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate, DeepLinkableViewController {
    
    @IBOutlet weak var rootScrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var departureLabel: UILabel!
    @IBOutlet weak var departureTextView: UITextView!
    @IBOutlet weak var arrivalLabel: UILabel!
    @IBOutlet weak var arrivalTextView: UITextView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneText: UITextView!
    //@IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var referencesView: UIView!
    
    // MARK: Properties
    
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // DeepLinkableViewController
    var wasDeepLinked = false
    
    // Section data
    
    // MARK: Navigation
    
    // MARK: Constructors
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        rootScrollView.minimumZoomScale = 1.0
        rootScrollView.maximumZoomScale = 2.0
    
        // Adjust baselines on text views to label
        departureTextView.alignBaseline(to: departureLabel)
        departureTextView.isScrollEnabled = false
        departureTextView.textContainer.lineFragmentPadding = 0.0
        arrivalTextView.alignBaseline(to: arrivalLabel)
        arrivalTextView.isScrollEnabled = false
        arrivalTextView.textContainer.lineFragmentPadding = 0.0
        phoneText.alignBaseline(to: phoneLabel)
        phoneText.isScrollEnabled = false
        phoneText.textContainer.lineFragmentPadding = 0.0
        
        //self.view.colourSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.dataRefreshed, object: nil)
        
        populateScreen(detectChanges: false, oldElement: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextViewDelegate
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func populateScreen(detectChanges: Bool, oldElement: GenericTransport?) {
        guard let transportElement = tripElement?.tripElement as? GenericTransport else {
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
        
        companyTextField.setText(transportElement.companyName ?? "<Unknown company>", detectChanges: detectChanges)

        let departureInfo = buildLocationInfo(stopName: transportElement.departureStop, location: transportElement.departureLocation, terminalName: transportElement.departureTerminalName, address: transportElement.departureAddress)
        departureTextView.setText(departureInfo, detectChanges: detectChanges)
        
        let arrivalInfo = buildLocationInfo(stopName: transportElement.arrivalStop, location: transportElement.arrivalLocation, terminalName: transportElement.arrivalTerminalName, address: transportElement.arrivalAddress)
        arrivalTextView.setText(arrivalInfo, detectChanges: detectChanges)

        phoneText.setText(transportElement.companyPhone, detectChanges: detectChanges)
        
        // Add references
        if let refList = transportElement.references {
            let horisontalHuggingLabel = companyLabel.contentHuggingPriority(for: .horizontal)
            let horisontalHuggingValue = companyTextField.contentHuggingPriority(for: .horizontal)
            let verticalHuggingLabel = companyLabel.contentHuggingPriority(for: .vertical)
            let verticalHuggingValue = companyTextField.contentHuggingPriority(for: .vertical)

            var oldReferences:NSDictionary? = nil
            let refDict = getAttributedReferences(refList, typeKey: "type", refKey: "refNo", urlKey: "urlLookup")
            if let oldTransport = oldElement, let oldRefs = oldTransport.references {
                oldReferences = getAttributedReferences(oldRefs, typeKey: "type", refKey: "refNo", urlKey: "urlLookup")
            }
            referencesView.addDictionaryAsGrid(refDict, oldDictionary: oldReferences, horisontalHuggingForLabel: horisontalHuggingLabel, verticalHuggingForLabel: verticalHuggingLabel, horisontalHuggingForValue: horisontalHuggingValue, verticalHuggingForValue: verticalHuggingValue, constrainValueFieldWidthToView: nil, highlightChanges: detectChanges)

        }
    }

    func buildLocationInfo(stopName: String?, location: String?, terminalName: String?, address: String?) -> String {
        var locationInfo = stopName ?? ""

        if let terminal = terminalName {
            locationInfo += (terminal == "" ? "" : "\n" + terminal)
        }
        if let address = address {
            locationInfo += (address == "" ? "" : "\n" + address)
        }
        if let location = location {
            locationInfo += (location == "" ? "" : "\n" + location)
        }
        return locationInfo
    }

    @objc func refreshTripElements() {
        print("Refreshing private transfer details")
        DispatchQueue.main.async(execute: {
            if let transportElement = self.tripElement?.tripElement as? GenericTransport {
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
        } else if let vc = vc as? PrivateTransportDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
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

