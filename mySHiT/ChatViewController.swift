//
//  ChatViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ChatViewController: UIViewController, UITextViewDelegate {
    // MARK: Constants
    
    // MARK: Properties
    @IBOutlet var rootView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var bottomSpacingConstraint: NSLayoutConstraint!
    
    var trip:AnnotatedTrip?
    var initialBottomConstraint:CGFloat?
    var chatTableController:ChatTableController?

    // MARK: Actions
    @IBAction func openSettings(_ sender: Any) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            //UIApplication.shared.openURL(appSettings)
        }
    }

    // MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.appendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.appendingPathComponent("sections")
    
    
    // MARK: Navigation
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
//        print("ChatView: Unwinding to main")
        //chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: "Some dummy comment"))
        //TripList.sharedList.getFromServer()
        return
    }
    
    
//    @IBAction func openSettings(_ sender: AnyObject) {
//        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
//            UIApplication.shared.openURL(appSettings)
//        }
//    }
    
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // print("Preparing for segue '\(segue.identifier)'")
        
        if let segueId = segue.identifier {
//            print("Chat View: Preparing for segue '\(segueId)'")
            switch (segueId) {
            //case Constant.segue.logout:
            //    logout()
                
            case Constant.segue.embedChatTable:
                chatTableController = segue.destination as? ChatTableController
                if let chatTableController = chatTableController {
                    chatTableController.trip = trip
                } else {
                    fatalError("Embedding chat table but incorrect controller type")
                }
                
            default:
                // No particular preparation needed.
                print("No special preparation necessary")
                break
            }
        } else {
            print("Chat View: Preparing for unidentified segue")
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
//        print("Chat View loaded")
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleNetworkError), name: NSNotification.Name(rawValue: Constant.notification.networkError), object: nil)

        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(title: "Alert", message: "You are not connected to the Internet", preferredStyle: UIAlertControllerStyle.alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //Present alert
            self.present(alert, animated: true, completion: nil)
        }
        
        messageTextView.delegate = self
        if let trip = trip {
             messageTextView.text = trip.trip.chatThread.messageBeingEntered
        }
        controlSendButton()
        
        initialBottomConstraint = bottomSpacingConstraint.constant
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.manageKeyboard), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.manageKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.manageKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        print("ChatView appeared")
        if !User.sharedUser.hasCredentials() {
            showLogonScreen(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let trip = trip {
            trip.trip.chatThread.messageBeingEntered = messageTextView.text
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func manageKeyboard (notification: Notification) {
        let isShowing = (notification.name == .UIKeyboardWillShow)
        
        var tabbarHeight: CGFloat = 0
        if let tabBarController = self.tabBarController {
            tabbarHeight = tabBarController.tabBar.frame.height
        }
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
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
    
    
    func handleNetworkError() {
        print("ChatListView: End refresh after network error")
        
        // First check if this view is currently active, if not, skip the alert
        if self.isViewLoaded && view.window != nil {
            print("ChatListView: Present error message")
            // Notify user
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: "Some dummy comment"),
                    message: NSLocalizedString(Constant.msg.connectError, comment: "Some dummy comment"),
                    preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
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
            print("ERROR: Trip not correctly set up for chat")
            return
        }
        
        let msg = ChatMessage(message: messageTextView.text)
        
        trip.trip.chatThread.append(msg)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
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

