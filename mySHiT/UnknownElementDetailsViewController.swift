//
//  UnknownElementDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-11-03.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class UnknownElementDetailsViewController: TripElementViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var topView: UIScrollView!
    @IBOutlet weak var messageTextView: UITextView!
    
    // Internal data
    var serverDataContentSize: CGSize? = nil
    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    
        topView.contentInsetAdjustmentBehavior = .never
        messageTextView.text = Constant.Message.unknownElement

        if let serverElements = tripElement?.serverData {
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
            return te.id == vcte.id
        } else {
            return false
        }
    }
}

