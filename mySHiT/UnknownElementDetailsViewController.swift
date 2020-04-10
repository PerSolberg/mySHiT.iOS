//
//  UnknownElementDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-03.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class UnknownElementDetailsViewController: UIViewController, UITextViewDelegate, DeepLinkableViewController {
    
    // MARK: Properties
    @IBOutlet weak var topView: UIScrollView!
    @IBOutlet weak var messageTextView: UITextView!
    
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Internal data
    var serverDataContentSize: CGSize? = nil
    
    // DeepLinkableViewController
    var wasDeepLinked = false
    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    
        automaticallyAdjustsScrollViewInsets = false
        messageTextView.text = Constant.msg.unknownElement

        if let serverElements = tripElement?.tripElement.serverData {
            topView.addDictionaryAsGrid(serverElements, horisontalHuggingForLabel: UILayoutPriority(rawValue: 251.0), verticalHuggingForLabel: UILayoutPriority(rawValue: 251.0), horisontalHuggingForValue: UILayoutPriority(rawValue: 249.0), verticalHuggingForValue: UILayoutPriority(rawValue: 249.0), constrainValueFieldWidthToView: nil)
            //self.view.colourSubviews()
            serverDataContentSize = topView.contentSize
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let size = serverDataContentSize {
            topView.contentSize = size
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    
    // MARK: UITextViewDelegate
    
    
    // MARK: Actions
    
    
    //
    // MARK: Functions
    //
    override func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else if let vc = vc as? UnknownElementDetailsViewController, let te = tripElement, let vcte = vc.tripElement {
            return te.tripElement.id == vcte.tripElement.id
        } else {
            return false
        }
    }
}

