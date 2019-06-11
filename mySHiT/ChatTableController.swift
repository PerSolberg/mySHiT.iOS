//
//  ChatTableController.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

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
        chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: Constant.dummyLocalisationComment))
        TripList.sharedList.getFromServer()
        return
    }
    
    
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    
    // MARK: Constructors
    func initCommon() {

    }
    
    
    required init?( coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }
    
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initCommon()
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        chatListTable.delegate = self
        
        chatListTable.estimatedRowHeight = 44
        chatListTable.rowHeight = UITableView.automaticDimension
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = chatListTable.backgroundColor
        refreshControl!.tintColor = UIColor.blue
        refreshControl!.addTarget(self, action: #selector(reloadChatThreadFromServer), for: .valueChanged)
    }
    
    func showLogonScreen(animated: Bool) {
        // Get login screen from storyboard and present it
        let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
        view.window!.makeKeyAndVisible()
        view.window!.rootViewController?.present(logonVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshChat), name: Constant.notification.chatRefreshed, object: nil)

        if let trip = trip {
            if let savedPosition = trip.trip.chatThread.exactPosition {
                //print("ChatTable: Restoring exact position: \(String(describing: savedPosition))")
                self.chatListTable.contentOffset = savedPosition
            } else {
                trip.trip.chatThread.savePosition()
            }
            trip.trip.refreshMessages()
        } else {
            os_log("ERROR: Trip not set correctly", type: .error)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        if !User.sharedUser.hasCredentials() {
            showLogonScreen(animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        trip!.trip.chatThread.exactPosition = chatListTable.contentOffset
        saveTrips()
    }

    
    @objc func refreshChat() {
        if let refreshControl = refreshControl {
            DispatchQueue.main.async(execute: {
                refreshControl.endRefreshing()
            })
        }
        guard let trip = trip else {
            os_log("ERROR: trip not correctly set up", type: .error)
            return
        }
        if trip.trip.chatThread.count == 0 {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noMessages, comment: Constant.dummyLocalisationComment))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
        DispatchQueue.main.async(execute: {
            guard let trip = self.trip else {
                os_log("ERROR: Trip not set up correctly, cannot reload", type: .error)
                return
            }
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
        // Should only be called if this view controller is displayed (notification observers
        // added in viewWillAppear and removed in viewWillDisappear

        // Notify user - and stop refresh in completion handler to ensure screen is properly updated
        // (ending refresh first, either in a separate DispatchQueue.main.sync call or in the alert async
        // closure didn't always dismiss the refrech control)
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: Constant.dummyLocalisationComment),
                message: NSLocalizedString(Constant.msg.connectError, comment: Constant.dummyLocalisationComment),
                preferredStyle: UIAlertController.Style.alert)
            alert.addAction(Constant.alert.actionOK)
            self.present(alert, animated: true, completion: {
                DispatchQueue.main.async {
                    if let refreshControl = self.refreshControl {
                        if refreshControl.isRefreshing {
                            refreshControl.endRefreshing()
                        }
                    }
                }
            })
        })
        
        if (TripList.sharedList.count == 0) {
            chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.networkUnavailable, comment: Constant.dummyLocalisationComment))
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
    }
    
    
    @objc func reloadChatThreadFromServer() {
        chatListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingChatThread, comment: Constant.dummyLocalisationComment))
        guard let trip = trip else {
            fatalError("Trip not configured correctly for chat thread")
        }
        
        trip.trip.chatThread.refresh(mode:.full)
    }
    
    
    func logonComplete(_ notification:Notification) {
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
            os_log("ERROR: trip not correctly set up", type: .error)
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


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
