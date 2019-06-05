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
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
//        print("Unknown Element Details: Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Unknown Element Details View loaded")
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        messageTextView.text = NSLocalizedString(Constant.msg.unknownElement, comment: Constant.dummyLocalisationComment)

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
        
        NotificationCenter.default.removeObserver(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextViewDelegate
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func refreshTripElements() {
//        print("Refreshing trip details - probably because data were refreshed")
        //updateSections()
        DispatchQueue.main.async(execute: {
            //self.title = self.trip?.trip.name
            //self.tripDetailsTable.reloadData()
        })
    }

    
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

