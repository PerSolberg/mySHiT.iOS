//
//  ChatViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

class ChatViewController: UIViewController, UITextViewDelegate, DeepLinkableViewController {
    // MARK: Constants
    
    // MARK: Properties
    @IBOutlet var rootView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var bottomSpacingConstraint: NSLayoutConstraint!
    
    var trip:AnnotatedTrip?
    var initialBottomConstraint:CGFloat?
    var chatTableController:ChatTableController?

    // DeepLinkableViewController
    var wasDeepLinked = false

    // MARK: Actions
    @IBAction func openSettings(_ sender: Any) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }

    // MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.appendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.appendingPathComponent("sections")
    
    
    // MARK: Navigation
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        return
    }
    
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // print("Preparing for segue '\(segue.identifier)'")
        if let segueId = segue.identifier {
            switch (segueId) {
            case Constant.segue.embedChatTable:
                chatTableController = segue.destination as? ChatTableController
                if let chatTableController = chatTableController {
                    chatTableController.trip = trip
                } else {
                    fatalError("Embedding chat table but incorrect controller type")
                }
                
            default:
                // No particular preparation needed.
                break
            }
        } else {
            os_log("Chat View: Preparing for unidentified segue", type: .error)
        }
    }
    
    
    // MARK: Constructors
    func initCommon() {
        // Initialisation logic common to all constructurs can go here
    }
    
    required init?( coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: Constant.dummyLocalisationComment),
                message: NSLocalizedString(Constant.msg.connectError, comment: Constant.dummyLocalisationComment),
                preferredStyle: UIAlertController.Style.alert)
            alert.addAction(Constant.alert.actionOK)
            self.present(alert, animated: true, completion: nil)
        }
         
        messageTextView.delegate = self
        if let trip = trip {
             messageTextView.text = trip.trip.chatThread.messageBeingEntered
        }
        controlSendButton()
        
        initialBottomConstraint = bottomSpacingConstraint.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.notification.networkError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !User.sharedUser.hasCredentials() {
            showLogonScreen(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        if let trip = trip {
            trip.trip.chatThread.messageBeingEntered = messageTextView.text
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func manageKeyboard (notification: Notification) {
        let isShowing = (notification.name == UIResponder.keyboardWillShowNotification)
        
        var tabbarHeight: CGFloat = 0
        if let tabBarController = self.tabBarController {
            tabbarHeight = tabBarController.tabBar.frame.height
        }
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            bottomSpacingConstraint?.constant = isShowing ? (endFrame!.size.height - tabbarHeight) : (initialBottomConstraint ?? 0.0)
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    //MARK: Functions
    func showLogonScreen(animated: Bool) {
        let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
        view.window!.makeKeyAndVisible()
        view.window!.rootViewController?.present(logonVC, animated: true, completion: nil)
    }
    
    
    @objc func handleNetworkError() {
        if let chatTableController = chatTableController {
            chatTableController.handleNetworkError()
        } else {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: Constant.dummyLocalisationComment),
                    message: NSLocalizedString(Constant.msg.connectError, comment: Constant.dummyLocalisationComment),
                    preferredStyle: UIAlertController.Style.alert)
                alert.addAction(Constant.alert.actionOK)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    

    // MARK: TextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        controlSendButton()
    }
    
    // MARK: Actions
    @IBAction func sendMessage(_ sender: Any) {
        guard let trip = trip else {
            os_log("ERROR: Trip not correctly set up for chat", type: .error)
            return
        }
        
        let msg = ChatMessage(message: messageTextView.text)
        
        trip.trip.chatThread.append(msg)
        NotificationCenter.default.post(name: Constant.notification.chatRefreshed, object: self)
        messageTextView.text = ""
        controlSendButton()
        messageTextView.resignFirstResponder()
        
        if let chatTableController = chatTableController {
            chatTableController.chatListTable.reloadData()
            let ip = IndexPath(row: trip.trip.chatThread.count - 1, section: 0)
            chatTableController.chatListTable.scrollToRow(at: ip, at: .bottom, animated: true)
        }
    }


    // MARK: Functions
    func controlSendButton() {
        if messageTextView.hasText {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
