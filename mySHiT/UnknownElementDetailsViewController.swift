//
//  UnknownElementDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-03.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class UnknownElementDetailsViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var topView: UIScrollView!
    @IBOutlet weak var messageTextView: UITextView!
    
    // Passed from TripDetailsViewController
    var tripElement:AnnotatedTripElement?
    var trip:AnnotatedTrip?
    
    // Internal data
    var serverDataContentSize: CGSize? = nil
    
    // MARK: Navigation
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        print("Unknown Element Details: Preparing for segue '\(String(describing: segue.identifier))'")
    }
    
    
    // MARK: Constructors
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Unknown Element Details View loaded")
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        messageTextView.text = NSLocalizedString(Constant.msg.unknownElement, comment: "Some dummy comment")

        if let serverElements = tripElement?.tripElement.serverData {
            topView.addDictionaryAsGrid(serverElements, horisontalHuggingForLabel: 251.0, verticalHuggingForLabel: 251.0, horisontalHuggingForValue: 249.0, verticalHuggingForValue: 249.0, constrainValueFieldWidthToView: nil)
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
    
}

