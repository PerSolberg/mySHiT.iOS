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
    struct Format {
        static let userListSeparator = NSLocalizedString("FMT.CHAT.USERLIST.SEPARATOR", comment:"")
    }
    
    struct CellIdentifier {
        static let messageOnly = "CustomChatCell"
        static let messageWithUserInfo = "CustomChatCellWithUserInfo"
        static let ownMessageOnly = "CustomChatCellOwn"
        static let ownMessageWithUserInfo = "CustomChatCellOwnWithUserInfo"
    }

    //
    // MARK: Properties
    //
    @IBOutlet var chatListTable: UITableView!
    
    var trip:AnnotatedTrip?
    
    
    //
    // MARK: Navigation
    //
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        chatListTable.setBackgroundMessage(Constant.Message.retrievingTrips)
        TripList.sharedList.getFromServer()
        return
    }
    
    
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    
    //
    // MARK: Constructors
    //
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    
    //
    // MARK: Callbacks
    //
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshChat), name: Constant.Notification.chatRefreshed, object: nil)

        if let trip = trip {
            if let savedPosition = trip.trip.chatThread.exactPosition {
                self.chatListTable.contentOffset = savedPosition
            } else {
                trip.trip.chatThread.savePosition()
            }
            trip.trip.refreshMessages()
        } else {
            os_log("ERROR: Trip not set correctly", log: OSLog.general, type: .error)
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        trip!.trip.chatThread.exactPosition = chatListTable.contentOffset
        saveTrips()
    }

    
    @objc func refreshChat() {
        endRefreshing()
        guard let trip = trip else {
            os_log("ERROR: trip not correctly set up", log: OSLog.general, type: .error)
            return
        }
        if trip.trip.chatThread.count == 0 {
            chatListTable.setBackgroundMessage(Constant.Message.noMessages)
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
        DispatchQueue.main.async(execute: {
            guard let trip = self.trip else {
                os_log("ERROR: Trip not set up correctly, cannot reload", log: OSLog.general, type: .error)
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
        showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.connectError) { self.endRefreshing() }
        
        if (TripList.sharedList.count == 0) {
            chatListTable.setBackgroundMessage(Constant.Message.networkUnavailable)
        } else {
            chatListTable.setBackgroundMessage(nil)
        }
    }
    
    
    @objc func reloadChatThreadFromServer() {
        chatListTable.setBackgroundMessage(Constant.Message.retrievingChatThread)
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
            os_log("ERROR: trip not correctly set up", log: OSLog.general, type: .error)
            return 0
        }

        return trip.trip.chatThread.count
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellIdentifier: String
        var seenByInfo:String? = nil
        
        guard let trip = trip else {
            fatalError("Trip is not correctly set up for chat.")
        }

        let msg = trip.trip.chatThread[indexPath.row]
        let ownMessage = (msg.userId == User.sharedUser.userId)

        switch msg.lastSeenBy {
        case .none:
            cellIdentifier = ownMessage ? CellIdentifier.ownMessageOnly : CellIdentifier.messageOnly

        case .everyone:
            cellIdentifier = ownMessage ? CellIdentifier.ownMessageWithUserInfo : CellIdentifier.messageWithUserInfo
            seenByInfo = Constant.Message.chatMsgSeenByEveryone

        case let .some(userList):
            cellIdentifier = ownMessage ? CellIdentifier.ownMessageWithUserInfo : CellIdentifier.messageWithUserInfo
            if userList.count > 1 {
                let finalName = userList.last!
                let nameList = userList.prefix(userList.count - 1).joined(separator: Format.userListSeparator)
                
                seenByInfo = String.localizedStringWithFormat(Constant.Message.chatMsgSeenByTwoOrMore, nameList, finalName) as String
            } else {
                seenByInfo = String.localizedStringWithFormat(Constant.Message.chatMsgSeenByOne, userList[0]) as String
            }
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? SHiTChatCell else {
            fatalError("Cell is not correct type.")
        }
        
        cell.message = msg
        cell.messageText.text = msg.messageText
        cell.messageText.backgroundColor = nil

        if !ownMessage {
            cell.userInitialsLabel.text = msg.userInitials
        }
        if let seenByInfo = seenByInfo {
            cell.seenByUsersText.text = seenByInfo
            cell.seenByUsersText.backgroundColor = nil
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    
    //
    // MARK: NSCoding
    //
    func saveTrips() {
        TripList.sharedList.saveToArchive()
    }
}
