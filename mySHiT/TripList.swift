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


public class TripList:NSObject, Sequence, NSCoding {
    typealias Index = Int
    
    static let sharedList = TripList()
    
    static let dqAccess = DispatchQueue(label: "no.andmore.mySHiT.triplist.access", attributes: .concurrent, target: .global())
    
    
    //
    // MARK: Properties
    //
    fileprivate var lastUpdateTS:ServerTimestamp?
    fileprivate var trips: [AnnotatedTrip]! = [AnnotatedTrip]()

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
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(lastUpdateTS, forKey: PropertyKey.lastUpdateTSKey)
        aCoder.encode(trips, forKey: PropertyKey.tripsKey)
    }

    
    required public init?( coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        lastUpdateTS = aDecoder.decodeObject(of: ServerTimestamp.self, forKey: PropertyKey.lastUpdateTSKey)
        trips  = aDecoder.decodeObject(forKey: PropertyKey.tripsKey) as? [AnnotatedTrip]
    }

    
    //
    // MARK: SequenceType
    //
    public func makeIterator() -> AnyIterator<AnnotatedTrip> {
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
    var count: Index {
        return trips.count
    }

    
    //
    // MARK: Functions
    //
    func getFromServer() {
        getFromServer(parentCompletionHandler: nil)
    }

    
    func getFromServer(parentCompletionHandler: (() -> Void)?) {
        if !User.sharedUser.hasCredentials() {
            os_log("User credentials missing or incomplete, cannot update from server", log: OSLog.general, type: .error)
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
            return
        }

        let tripListResource = SHiTResource.tripList(parameters: [])
        RESTRequest.get(tripListResource) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                self.update(fromDictionary: responseDictionary)
            }
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
        }
        return
    }
    
    
    // Update memory structure with data received from server
    func update(fromDictionary responseData: NSDictionary!) {
        TripList.dqAccess.async(flags: .barrier) {
            self.performUpdate(fromDictionary: responseData)
            os_log("Updates complete, signalling refresh", log: OSLog.general, type: .debug)
            NotificationCenter.default.post(name: Constant.Notification.dataRefreshed, object: self)
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

        let initialLoad = ( lastUpdateTS == nil )
        if contentType == SHiTResource.Result.contentList {
            if let lastUpdateTS = lastUpdateTS, serverTS <= lastUpdateTS {
                return;
            }
            lastUpdateTS = serverTS
        }

        // Add or update trips received from server
        var changed = false
        var tripIDs = Set<Int>()
        for tripObj in newTrips {
            if let tripDict = tripObj as? NSDictionary, let tripId = tripDict[Constant.JSON.tripId] as? Int {
                tripIDs.insert(tripId)
                if let aTrip = trip(byId: tripId) {
                    let detailsAlreadyLoaded = aTrip.trip.detailsLoaded
                    let tripChanged = aTrip.trip.update(fromDictionary: tripDict, updateTS: serverTS)
                    if tripChanged {
                        changed = true
                        aTrip.modified = .Changed
                    } else if detailsAlreadyLoaded != aTrip.trip.detailsLoaded {
                        changed = true
                    }
                } else {
                    if let newTrip = Trip(fromDictionary: tripDict, updateTS: serverTS) {
                        newTrip.registerForPushNotifications()
                        trips.append( AnnotatedTrip(section: .Historic, trip: newTrip, modified: initialLoad ? .Unchanged : .New)! )
                        if let tripTense = newTrip.tense, tripTense == .future || tripTense == .present {
                            DispatchQueue.global().async {
                                newTrip.loadDetails(parentCompletionHandler: nil)
                            }
                        }
                        changed = true
                    } else {
                        os_log("Unable to create trip from dictionary", log: OSLog.general, type: .error)
                    }
                }
            } else {
                os_log("Trip data is not dictionary or doesn't have ID", log: OSLog.general, type: .error)
            }
        }
        
        if contentType == SHiTResource.Result.contentList {
            // Remove trips no longer in list - but only if we received complete list
            for (ix, aTrip) in trips.enumerated().reversed() {
                if !tripIDs.contains(aTrip.trip.id) {
                    aTrip.trip.deregisterPushNotifications()
                    trips.remove(at: ix)
                    changed = true
                }
            }
        }
        
        if changed {
            trips.sort(by:{ !($0.trip.isBefore($1.trip) ?? false) })
            saveToArchive()
        }
        
        // Set application badge
        DispatchQueue.main.async(execute: {
            UIApplication.shared.applicationIconBadgeNumber = self.changes()
        })
    }
    
    
    // Load from keyed archive
    func loadFromArchive() {
        do {
            let fileData = try Data(contentsOf: Constant.Archive.tripsURL)
            trips = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, AnnotatedTrip.self], from: fileData) as? [AnnotatedTrip] ?? [AnnotatedTrip]()
            refreshNotifications()
        } catch {
            os_log("Failed to load sections: %{public}s", log: OSLog.general, type: .error, error.localizedDescription)
        }

    }
    

    func saveToArchive() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: trips!, requiringSecureCoding: false)
            try data.write(to: Constant.Archive.tripsURL)
            os_log("Trips saved to iOS keyed archive", log: OSLog.general, type: .info)
        } catch {
            os_log("Failed to save trips: %{public}s", log: OSLog.general, type: .error, error.localizedDescription)
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
        lastUpdateTS = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    

    func changes() -> Int {
        var changes = 0
        for t in trips {
            let tripChanges = t.trip.changes()
            
            if tripChanges > 0 {
                changes += tripChanges
            } else if t.modified != .Unchanged {
                changes += 1
            }
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
