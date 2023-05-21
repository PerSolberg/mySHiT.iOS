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

class ChatViewController: UIViewController, UITextViewDelegate, DeepLinkableViewController, UNUserNotificationCenterDelegate {
    //
    // MARK: Constants
    //
    
    //
    // MARK: Properties
    //
    @IBOutlet var rootView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var bottomSpacingConstraint: NSLayoutConstraint!
    
    var trip:AnnotatedTrip?
    var initialBottomConstraint:CGFloat?
    var chatTableController:ChatTableController?

    // DeepLinkableViewController
    var wasDeepLinked = false

    // UNUserNotificationCenterDelegate
    var oldUserNotificationCenterDelegate:UNUserNotificationCenterDelegate?
    
    //
    // MARK: Actions
    //
    @IBAction func openSettings(_ sender: Any) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }


    //
    // MARK: Navigation
    //
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        return
    }
    
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        if let segueId = segue.identifier {
            switch (segueId) {
            case Constant.Segue.embedChatTable:
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
            os_log("Chat View: Preparing for unidentified segue", log: OSLog.general, type: .error)
        }
    }
    
    
    //
    // MARK: Constructors
    //
    required init?( coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!RSUtilities.isNetworkAvailable(SHiTResource.host)) {
            //If host is not reachable, display a UIAlertController informing the user
            showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.connectError, completion: nil)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manageKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        messageTextView.delegate = self
        if let trip = trip {
             messageTextView.text = trip.trip.chatThread.messageBeingEntered
        }
        controlSendButton()
        
        initialBottomConstraint = bottomSpacingConstraint.constant
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        oldUserNotificationCenterDelegate = UNUserNotificationCenter.current().delegate
        UNUserNotificationCenter.current().delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.Notification.networkError, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        UNUserNotificationCenter.current().delegate = oldUserNotificationCenterDelegate
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Constant.Notification.networkError, object: nil)
        if let trip = trip {
            trip.trip.chatThread.messageBeingEntered = messageTextView.text
        }
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
    
    
    //
    //MARK: Functions
    //
    @objc func handleNetworkError() {
        if let chatTableController = chatTableController {
            chatTableController.handleNetworkError()
        } else {
            showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.connectError, completion: nil)
        }
    }
    

    //
    // MARK: TextViewDelegate
    //
    func textViewDidChange(_ textView: UITextView) {
        controlSendButton()
    }
    
    
    //
    // MARK: UNUserNotificationCenterDelegate
    //
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        guard let currentUserId = User.sharedUser.userId else {
            completionHandler([])
            fatalError("Unable to get logged on user ID.")
        }

        if let _ = notification.request.trigger as? UNPushNotificationTrigger, let ntf = RemoteNotification(from: notification.request.content.userInfo), ntf.changeType == Constant.ChangeType.chatMessage && ntf.changeOperation == Constant.ChangeOperation.insert, let fromUserId = ntf.fromUserId {
            if fromUserId == currentUserId {
                completionHandler([])
            } else {
                completionHandler([.sound])
            }
        } else {
            oldUserNotificationCenterDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler) ?? {
                completionHandler([/*.alert,*/.badge, .banner, .sound]) }()
        }
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        oldUserNotificationCenterDelegate?.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler) ?? {
            completionHandler() }()
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        oldUserNotificationCenterDelegate?.userNotificationCenter?(center, openSettingsFor: notification) ?? {
            os_log("Unable to invoke old delegate _:openSettingsFor", log: OSLog.notification, type: .debug)
            }()
    }
  
    
    //
    // MARK: Actions
    //
    @IBAction func sendMessage(_ sender: Any) {
        guard let trip = trip else {
            os_log("ERROR: Trip not correctly set up for chat", log: OSLog.general, type: .error)
            return
        }
        
        let msg = ChatMessage(message: messageTextView.text)
        
        trip.trip.chatThread.append(msg)
        NotificationCenter.default.post(name: Constant.Notification.chatRefreshed, object: self)
        messageTextView.text = ""
        controlSendButton()
        messageTextView.resignFirstResponder()
        
        if let chatTableController = chatTableController {
            chatTableController.chatListTable.reloadData()
            let ip = IndexPath(row: trip.trip.chatThread.count - 1, section: 0)
            chatTableController.chatListTable.scrollToRow(at: ip, at: .bottom, animated: true)
        }
    }


    //
    // MARK: Functions
    //
    func controlSendButton() {
        sendButton.isEnabled = messageTextView.hasText
    }
    
    
    //
    // MARK: Static functions
    //
    static func pushDeepLinked(for tripId:Int) {
        guard let navVC = UIApplication.rootNavigationController else {
            os_log("Unable to get root navigation controller", log: OSLog.general, type: .error)
            return
        }
        if let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, trip.id == tripId {
            os_log("Message for current chat - No need to do anything, already handled", log: OSLog.general, type: .debug)
        } else {
            navVC.popDeepLinkedControllers()
            // Push correct view controller onto navigation stack
            if let annotatedTrip = TripList.sharedList.trip(byId: tripId) {
                let cvc = ChatViewController.instantiate(fromAppStoryboard: .Main)
                cvc.wasDeepLinked = true
                cvc.trip = annotatedTrip
                navVC.pushViewController(cvc, animated: true)
            } else {
                os_log("Unable to get trip", log: OSLog.general, type: .error)
            }
        }

    }
}
