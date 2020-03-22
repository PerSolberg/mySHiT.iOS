//
//  TripList.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-27.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import FirebaseMessaging
import UIKit
import UserNotifications
import os


class TripList:NSObject, Sequence, NSCoding {
    typealias Index = Int
    
    static let sharedList = TripList()
    
    static let dqAccess = DispatchQueue(label: "no.andmore.mySHiT.triplist.access", attributes: .concurrent, target: .global())
    
    
    //
    // MARK: Properties
    //
    fileprivate var lastUpdateTS:ServerTimestamp?
    fileprivate var trips: [AnnotatedTrip]! = [AnnotatedTrip]()
    fileprivate var rsRequest: RSTransactionRequest = RSTransactionRequest()
    fileprivate var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: Constant.REST.mySHiT.baseUrl, path: "trip", parameters: [:] )


    fileprivate struct PropertyKey {
        static let tripsKey = "trips"
        static let lastUpdateTSKey = "lastUpdate"
    }


    //
    // MARK: Initalisers
    //
    // Prevent other classes from instantiating - TripList is singleton!
    override fileprivate init () {
    }

    
    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(lastUpdateTS, forKey: PropertyKey.lastUpdateTSKey)
        aCoder.encode(trips, forKey: PropertyKey.tripsKey)
    }

    
    required init?( coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        lastUpdateTS = aDecoder.decodeObject(forKey: PropertyKey.lastUpdateTSKey) as? ServerTimestamp
        trips  = aDecoder.decodeObject(forKey: PropertyKey.tripsKey) as? [AnnotatedTrip]
    }

    
    //
    // MARK: SequenceType
    //
    func makeIterator() -> AnyIterator<AnnotatedTrip> {
        // keep the index of the next trip in the iteration
        var nextIndex = 0
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next trip in the iteration
        return AnyIterator {
            if (nextIndex >= self.trips.count) {
                return nil
            }
            nextIndex += 1
            return self.trips[nextIndex - 1]
        }
    }

    
    func reverse() -> AnyIterator<AnnotatedTrip> {
        // keep the index of the next trip in the iteration
        var nextIndex = trips.count-1
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next trip in the iteration
        return AnyIterator {
            if (nextIndex < 0) {
                return nil
            }
            nextIndex -= 1
            //print(nextIndex)
            return self.trips[nextIndex + 1]
        }
    }
    
    
    var indices:CountableRange<Int> {
        return trips.indices
    }
    
    
    //
    // MARK: Indexable
    //
    subscript(position: Int) -> AnnotatedTrip? {
        if position >= trips.count {
            return nil
        }
        return trips[position]
    }
    

    //
    // MARK: CollectionType
    //
    var count: Index /*.Distance */ {
        return trips.count
    }

    
    //
    // MARK: Functions
    //
    func getFromServer() {
        getFromServer(parentCompletionHandler: nil)
    }

    
    func getFromServer(parentCompletionHandler: (() -> Void)?) {
        let userCred = User.sharedUser.getCredentials()
        
        if ( userCred.name == nil || userCred.password == nil || userCred.urlsafePassword == nil ) {
            os_log("User credentials missing or incomplete, cannot update from server", log: OSLog.general, type: .error)
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
            return
        }
        
        rsTransGetTripList.parameters = [ Constant.REST.mySHiT.Param.userName : userCred.name!,
            Constant.REST.mySHiT.Param.password : userCred.urlsafePassword!]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                os_log("Error : %{public}s", log: OSLog.webService, type: .error,  error.localizedDescription)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                os_log("Error : %{public}s", log: OSLog.webService, type: .error,  errMsg)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else {
                self.update(fromDictionary: responseDictionary)
                NotificationCenter.default.post(name: Constant.notification.dataRefreshed, object: self)
            }
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
        })
        return
    }
    
    
    // Update memory structure with data received from server
    func update(fromDictionary responseData: NSDictionary!) {
        TripList.dqAccess.async(flags: .barrier) {
            self.performUpdate(fromDictionary: responseData)
        }
    }

    
    fileprivate func performUpdate(fromDictionary responseData: NSDictionary!) {
        guard let newTrips = responseData[Constant.JSON.queryTripList] as? NSArray else {
            os_log("Response does not contain '%{public}s' element", log: OSLog.general, type: .error, Constant.JSON.queryTripList)
            return
        }
        guard let contentType = responseData[Constant.JSON.queryContent] as? String else {
            os_log("Response does not contain '%{public}s' element", log: OSLog.general, type: .error, Constant.JSON.queryContent)
            return
        }
        guard let serverTSDict = responseData[Constant.JSON.srvTS] as? NSDictionary, let serverTS = ServerTimestamp(fromDictionary: serverTSDict) else {
            os_log("Response does not contain valid '%{public}s' element", log: OSLog.general, type: .error, Constant.JSON.srvTS)
            return
        }
        
        if contentType == Constant.REST.mySHiT.ResultValue.contentList {
            if let lastUpdateTS = lastUpdateTS, serverTS <= lastUpdateTS {
                return;
            }
            lastUpdateTS = serverTS
        }

        // Add or update trips received from server
        var tripIDs = Set<Int>()
        var added = false
        for tripObj in newTrips {
            if let tripDict = tripObj as? NSDictionary, let tripId = tripDict[Constant.JSON.tripId] as? Int {
                tripIDs.insert(tripId)
                if let aTrip = trip(byId: tripId) {
                    let changed = aTrip.trip.update(fromDictionary: tripDict, updateTS: serverTS)
                    if changed {
                        aTrip.modified = .Changed
//                        aTrip.trip.refreshNotifications()
                    }
                } else {
                    if let newTrip = Trip(fromDictionary: tripDict, updateTS: serverTS) {
                        newTrip.registerForPushNotifications()
                        trips.append( AnnotatedTrip(section: .Historic, trip: newTrip, modified: .New)! )
                        added = true
                    } else {
                        os_log("Unable to create trip from dictionary", log: OSLog.general, type: .error)
                    }
                }
            } else {
                os_log("Trip data is not dictionary or doesn't have ID", log: OSLog.general, type: .error)
            }
        }
        
        if contentType == Constant.REST.mySHiT.ResultValue.contentList {
            // Remove trips no longer in list - but only if we received complete list
            for (ix, aTrip) in trips.enumerated().reversed() {
                if !tripIDs.contains(aTrip.trip.id) {
                    aTrip.trip.deregisterPushNotifications()
                    trips.remove(at: ix)
                }
            }
        }
        
        // If new trips were added, sort the list
        if added {
            trips.sort(by:{ $0.trip.isBefore($1.trip) ?? false  })
        }

        // Set application badge
        DispatchQueue.main.async(execute: {
            UIApplication.shared.applicationIconBadgeNumber = self.changes()
        })
    }
    
    
    // Load from keyed archive
    func loadFromArchive(_ path:String) {
        let newTripList = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [AnnotatedTrip]
        trips = newTripList ?? [AnnotatedTrip]()
        refreshNotifications()
    }


    func saveToArchive(_ path:String) {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(trips!, toFile: path)
        if !isSuccessfulSave {
            os_log("Failed to save trips", log: OSLog.general, type: .error)
        } else {
            os_log("Trips saved to iOS keyed archive", log: OSLog.general, type: .info)
        }
    }
    
    
    func trip(byId tripId: Int) -> AnnotatedTrip? {
        for t in trips {
            if t.trip.id == tripId {
                return t
            }
        }
        return nil
    }
    

    func trip(byCode tripCode: String) -> AnnotatedTrip? {
        for t in trips {
            if t.trip.code == tripCode {
                return t
            }
        }
        return nil
    }
    
    
    func tripElement(byId tripElementId: Int) -> (AnnotatedTrip, AnnotatedTripElement)? {
        for t in trips {
            if let te = t.trip.tripElement(byId: tripElementId) {
                return (t, te)
            }
        }
        return nil
    }
    
    
    func clear() {
        deregisterPushNotifications()

        // Empty list and cancel all notifications
        trips = [AnnotatedTrip]()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    

    func changes() -> Int {
        var changes = 0
        for t in trips {
            changes += t.trip.changes()
        }
        return changes
    }


    func deregisterPushNotifications() {
        for t in trips {
            t.trip.deregisterPushNotifications()
        }
    }
    
    
    func registerForPushNotifications() {
        for t in trips {
            t.trip.registerForPushNotifications()
        }
    }

    
    func refreshNotifications() {
        for t in trips {
            t.trip.refreshNotifications()
        }
    }
}
