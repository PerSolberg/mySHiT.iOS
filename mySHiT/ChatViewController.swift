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
    
    var trip:AnnotatedTrip?
    
    // MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.appendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.appendingPathComponent("sections")
    
    
    // MARK: Navigation
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        print("ChatView: Unwinding to main")
        //chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: "Some dummy comment"))
        //TripList.sharedList.getFromServer()
        return
    }
    
    
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(appSettings)
        }
    }
    
    
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // print("Preparing for segue '\(segue.identifier)'")
        
        if let segueId = segue.identifier {
            print("Chat View: Preparing for segue '\(segueId)'")
            switch (segueId) {
            //case Constant.segue.logout:
            //    logout()
                
            case Constant.segue.embedChatTable:
                let destinationController = segue.destination as! ChatTableController
                destinationController.trip = trip
                
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
        print("Chat View loaded")
        print("Current language = \((Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode)!)")
        super.viewDidLoad()
        
        controlSendButton()
        /*
        NotificationCenter.default.addObserver(self, selector: #selector(TripListViewController.handleNetworkError), name: NSNotification.Name(rawValue: Constant.notification.networkError), object: nil)
        */
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.refreshChat), name: NSNotification.Name(rawValue: Constant.notification.chatRefreshed), object: nil)

        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(title: "Alert", message: "You are not connected to the Internet", preferredStyle: UIAlertControllerStyle.alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //Present alert
            self.present(alert, animated: true, completion: nil)
        }

        /*
        if let trip = trip {
            print("Refreshing messages from server")
            trip.trip.refreshMessages()
        } else {
            print("ERROR: Trip not set correctly")
        }
        print("Data should be ready - refresh list")
        */
        //DispatchQueue.main.async(execute: {
        //    self.chatListTable.reloadData()
        //})
        
        // Set up refresh
        /*
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = chatListTable.backgroundColor //UIColor.cyanColor()
        refreshControl!.tintColor = UIColor.blue  //whiteColor()
        refreshControl!.addTarget(self, action: #selector(TripListViewController.reloadTripsFromServer), for: .valueChanged)
        */
    }
    
    func showLogonScreen(animated: Bool) {
        // Get login screen from storyboard and present it
        let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
        view.window!.makeKeyAndVisible()
        view.window!.rootViewController?.present(logonVC, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("ChatView appeared")
        if !User.sharedUser.hasCredentials() {
            // Show login view
            print("Show logon screen")
            showLogonScreen(animated: false)
        }
        
        print("Normal processing")
    }
    
    
    func refreshChat() {
        //refreshControl!.endRefreshing()
        print("ChatView: Refreshing list, probably because data were updated")
        /*
        if let msgList = trip?.trip.messages {
            if msgList.count == 0 {
                chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noMessages, comment: "Some dummy comment"))
            } else {
                chatListTable.setBackgroundMessage(nil)
            }
        } else {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noMessages, comment: "Some dummy comment"))
        }
        DispatchQueue.main.async(execute: {
            self.chatListTable.reloadData()
        })
        saveTrips()
        */
    }
    
    /*
    func refreshTripList() {
        refreshControl!.endRefreshing()
        print("TripListView: Refreshing list, probably because data were updated")
        if (TripList.sharedList.count == 0) {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noTrips, comment: "Some dummy comment"))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
        DispatchQueue.main.async(execute: {
            self.chatListTable.reloadData()
        })
        saveTrips()
    }
     */
    
    
    func handleNetworkError() {
        //refreshControl!.endRefreshing()
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
        /*
        if (TripList.sharedList.count == 0) {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.networkUnavailable, comment: "Some dummy comment"))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
        */
    }
    
    
    func reloadTripsFromServer() {
        //chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: "Some dummy comment"))
        TripList.sharedList.getFromServer()
        //refreshTripList()
    }
    
    
    func logonComplete(_ notification:Notification) {
        print("ChatListView: Logon complete")
        reloadTripsFromServer()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: NSCoding
    func saveTrips() {
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
        saveSections()
    }
    
    
    func saveSections() {
    }
    
    
    func loadTrips() -> [TripListSectionInfo]? {
        print("Loading trips from iOS keyed archive")
        TripList.sharedList.loadFromArchive(TripListViewController.ArchiveTripsURL.path)
        print("Loading sections from iOS keyed archive")
        let sectionList = NSKeyedUnarchiver.unarchiveObject(withFile: TripListViewController.ArchiveSectionsURL.path) as? [TripListSectionInfo]
        return sectionList
    }
    

    // MARK: TextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        controlSendButton()
    }
    
    // MARK: Actions
    @IBAction func sendMessage(_ sender: Any) {
        print("sendMessage triggered")
        guard let trip = trip else {
            print("ERROR: Trip not correctly set up for chat")
            return
        }
        
        let msg = ChatMessage(message: messageTextView.text)
        
        trip.trip.chatThread.append(msg)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
        messageTextView.text = ""
        controlSendButton()
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

