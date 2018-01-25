//
//  ChatTableController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ChatTableController: UITableViewController {
    // MARK: Constants
    
    
    // MARK: Properties
    @IBOutlet var chatListTable: UITableView!
    
    var trip:AnnotatedTrip?
    
    // MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.appendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.appendingPathComponent("sections")
    
    
    // MARK: Navigation
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: "Some dummy comment"))
        TripList.sharedList.getFromServer()
        return
    }
    
    
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            //UIApplication.shared.openURL(appSettings)
        }
    }
    
    
    // MARK: Constructors
    func initCommon() {

    }
    
    
    required init?( coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }
    
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        initCommon()
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        //print("Chat Table loaded")
        //print("Current language = \((Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode)!)")
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(ChatTableController.refreshChat), name: NSNotification.Name(rawValue: Constant.notification.chatRefreshed), object: nil)
        /*
         if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
         _ = RSUtilities.networkConnectionType("www.shitt.no")
         
         //If host is not reachable, display a UIAlertController informing the user
         let alert = UIAlertController(title: "Alert", message: "You are not connected to the Internet", preferredStyle: UIAlertControllerStyle.Alert)
         
         //Add alert action
         alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
         
         //Present alert
         self.presentViewController(alert, animated: true, completion: nil)
         }
         */

        chatListTable.delegate = self
        
        chatListTable.estimatedRowHeight = 44
        chatListTable.rowHeight = UITableViewAutomaticDimension
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = chatListTable.backgroundColor //UIColor.cyanColor()
        refreshControl!.tintColor = UIColor.blue  //whiteColor()
        refreshControl!.addTarget(self, action: #selector(ChatTableController.reloadChatThreadFromServer), for: .valueChanged)
    }
    
    func showLogonScreen(animated: Bool) {
        // Get login screen from storyboard and present it
        let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
        view.window!.makeKeyAndVisible()
        view.window!.rootViewController?.present(logonVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let trip = trip {
            //print("Chat Table: Refreshing messages from server")
            if let savedPosition = trip.trip.chatThread.exactPosition {
                print("ChatTable: Restoring exact position: \(String(describing: savedPosition))")
                self.chatListTable.contentOffset = savedPosition
            } else {
                trip.trip.chatThread.savePosition()
            }
            trip.trip.refreshMessages()
        } else {
            print("ERROR: Trip not set correctly")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
//        print("ChatTable appeared")
        if !User.sharedUser.hasCredentials() {
            // Show login view
            print("Show logon screen")
            showLogonScreen(animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        print("View will disappear, save status")
        trip!.trip.chatThread.exactPosition = chatListTable.contentOffset
        saveTrips()
    }


    func refreshChat() {
        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
        }
//        print("ChatTable: Refreshing list, probably because data were updated")
        guard let trip = trip else {
            print("ERROR: trip not correctly set up")
            return
        }
        if trip.trip.chatThread.count == 0 {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noMessages, comment: "Some dummy comment"))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
        DispatchQueue.main.async(execute: {
            guard let trip = self.trip else {
                print("ERROR: Trip not set up correctly, cannot reload")
                return
            }
            //trip.trip.chatThread.savePosition()
            self.chatListTable.reloadData()
            if trip.trip.chatThread.restorePosition() {
                self.restorePosition()
            }
        })
        saveTrips()
    }
    
    func restorePosition() {
        if let trip = trip, let lastSeenRow = trip.trip.chatThread.lastDisplayedItem {
            let ip = IndexPath(row: lastSeenRow, section: 0)
            self.chatListTable.scrollToRow(at: ip, at: trip.trip.chatThread.lastDisplayedItemPosition, animated: false)
        }
    }

    func handleNetworkError() {
        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
        }
//        print("ChatTableView: End refresh after network error")
        
        // First check if this view is currently active, if not, skip the alert
        if self.isViewLoaded && view.window != nil {
            print("ChatTableView: Present error message")
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
        
        if (TripList.sharedList.count == 0) {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.networkUnavailable, comment: "Some dummy comment"))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
    }
    
    
    func reloadChatThreadFromServer() {
        chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingChatThread, comment: "Some dummy comment"))
        guard let trip = trip else {
            fatalError("Trip not configured correctly for chat thread")
        }
        
        trip.trip.chatThread.refresh(mode:.full)
        //refreshTripList()
    }
    
    
    func logonComplete(_ notification:Notification) {
        print("ChatTableView: Logon complete")
        reloadChatThreadFromServer()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //
    // MARK: UITableViewDataSource methods
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let trip = trip else {
            print("ERROR: trip not correctly set up")
            return 0
        }

        return trip.trip.chatThread.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var kCellIdentifier: String
        var seenByInfo:String = ""
        let kCellIdentifierMessageOnly = "CustomChatCell"
        let kCellIdentifierWithUserInfo = "CustomChatCellWithUserInfo"
        let kCellIdentifierOwnMessageOnly = "CustomChatCellOwn"
        let kCellIdentifierOwnMessageWithUserInfo = "CustomChatCellOwnWithUserInfo"
        
        guard let trip = trip else {
            fatalError("Trip is not correctly set up for chat.")
        }

        let msg = trip.trip.chatThread[indexPath.row]
        let ownMessage = (msg.userId == User.sharedUser.userId)
        let showSeenByInfo = !(msg.lastSeenBy.contains(ChatThread.LastSeenByNone) || msg.lastSeenBy.count == 0)
        if !showSeenByInfo {
            kCellIdentifier = ownMessage ? kCellIdentifierOwnMessageOnly : kCellIdentifierMessageOnly
        } else {
            kCellIdentifier = ownMessage ? kCellIdentifierOwnMessageWithUserInfo : kCellIdentifierWithUserInfo

            if msg.lastSeenBy.contains(ChatThread.LastSeenByEveryone) {
                seenByInfo = String.localizedStringWithFormat(NSLocalizedString(Constant.msg.chatMsgSeenByEveryone, comment: "") ) as String
            } else if msg.lastSeenBy.count > 1 {
                let finalName = msg.lastSeenBy.last!
                let nameList = msg.lastSeenBy.prefix(msg.lastSeenBy.count - 1).joined(separator: ", ")
                
                seenByInfo = String.localizedStringWithFormat(NSLocalizedString(Constant.msg.chatMsgSeenByTwoOrMore, comment:""), nameList, finalName) as String
            } else {
                seenByInfo = String.localizedStringWithFormat(NSLocalizedString(Constant.msg.chatMsgSeenByOne, comment:""), msg.lastSeenBy[0]) as String
            }
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier) as? SHiTChatCell else {
            fatalError("Cell is not correct type.")
        }
        
        cell.message = msg
        cell.messageText.text = msg.messageText
        cell.messageText.backgroundColor = nil

        if !ownMessage {
            cell.userInitialsLabel.text = msg.userInitials
        }
        if showSeenByInfo {
            cell.seenByUsersText.text = seenByInfo
            cell.seenByUsersText.backgroundColor = nil
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    
    //
    // MARK: Section header callbacks
    //
    
    //
    // MARK: NSCoding
    //
    func saveTrips() {
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }
    
    
    //
    // MARK: Actions
    //

    
    //
    // MARK: Functions
    //
}

