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

class TripList:NSObject, Sequence, NSCoding {
    //typealias Index = Array<AnnotatedTrip>.Index
    typealias Index = Int
    //typealias SubSequence = Array<AnnotatedTrip>.SubSequence
    //typealias SubSequence = ArraySlice<AnnotatedTrip>
    //typealias Element = AnnotatedTrip
    
    static let sharedList = TripList()
    
    // Prevent other classes from instantiating - User is singleton!
    override fileprivate init () {
    }

    required init?( coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        trips  = aDecoder.decodeObject(forKey: PropertyKey.tripsKey) as! [AnnotatedTrip]
    }

    // Public properties
    
    // Private properties
    fileprivate var trips: [AnnotatedTrip]! = [AnnotatedTrip]()
    fileprivate var rsRequest: RSTransactionRequest = RSTransactionRequest()
    fileprivate var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: "https://www.shitt.no/mySHiT", path: "trip", parameters: ["userName":"dummy@default.com","password":"******"])


    fileprivate struct PropertyKey {
        static let tripsKey = "trips"
    }


    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trips, forKey: PropertyKey.tripsKey)
    }

    // MARK: SequenceType
    func makeIterator() -> AnyIterator<AnnotatedTrip> {
        // keep the index of the next trip in the iteration
        var nextIndex = 0
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next car in the iteration
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
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next car in the iteration
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
    
    // MARK: Indexable
    subscript(position: Int) -> AnnotatedTrip? {
        if position >= trips.count {
            return nil
        }
        return trips[position]
    }
    /*
    var startIndex: Index {
        return trips.startIndex
    }
    var endIndex: Index {
        return trips.endIndex
    }
    */
    

    // MARK: CollectionType
    var count: Index /*.Distance */ {
        return trips.count
    }
    /*
    var first: Element? {
        return trips.first
    }
    var isEmpty: Bool {
        return trips.isEmpty
    }
    subscript (bounds: Range<Index>) -> SubSequence {
        return trips[bounds]
    }
    func prefixThrough(position: Index) -> SubSequence {
        return trips.prefixThrough(position)
    }
    func prefixUpTo(end: Index) -> SubSequence {
        return trips.prefixUpTo(end)
    }
    func suffixFrom(start: Index) -> SubSequence {
        return trips.suffixFrom(start)
    }
    */

    
    // Functions
    func getFromServer() {
        getFromServer(parentCompletionHandler: nil)
    }

    func getFromServer(parentCompletionHandler: (() -> Void)?) {
        let userCred = User.sharedUser.getCredentials()
        
        if ( userCred.name == nil || userCred.password == nil || userCred.urlsafePassword == nil ) {
            print("User credentials missing or incomplete, cannot update from server")
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
            return
        }
        //assert( userCred.name != nil );
        //assert( userCred.password != nil );
        //assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransGetTripList.parameters = [ "userName":userCred.name!,
            "password":userCred.urlsafePassword!,
            "sectioned":"0",
            "details":"non-historic"]
        
        //Send request
        print("TripList: Send request to refresh data")
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                let serverData = responseDictionary?[Constant.JSON.queryResults] as! NSArray
                self.copyServerData(serverData)
                print("TripList: Server data received, notifying view controllers")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.tripsRefreshed), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.tripElementsRefreshed), object: self)
            }
            if let parentCompletionHandler = parentCompletionHandler {
                parentCompletionHandler()
            }
        })
        return
    }
    
    
    // Copy data received from server to memory structure
    fileprivate func copyServerData(_ serverData: NSArray!) {
        // Clear current data and repopulate from server data
        var newTripList = [AnnotatedTrip]()
        for svrItem in serverData {
            let newTrip = Trip(fromDictionary: svrItem as! NSDictionary)
            newTripList.append( AnnotatedTrip(section: .Historic, trip: newTrip!, modified: .Unchanged)! )
        }

        // Determine changes
        if !trips.isEmpty {
            for newTrip in newTripList {
                let matchingOldTrips = trips.filter( { (t:AnnotatedTrip) -> Bool in
                    return t.trip.id == newTrip.trip.id
                })
                if matchingOldTrips.isEmpty {
                    newTrip.modified = .New
                    newTrip.trip.registerForPushNotifications()
                } else {
                    newTrip.trip.compareTripElements(matchingOldTrips[0].trip)
                    if !newTrip.trip.isEqual(matchingOldTrips[0].trip) {
                        newTrip.modified = .Changed
                    }
                    newTrip.trip.copyState(from: matchingOldTrips[0].trip)
                }
            }

            // Deregister notifications on old trips no longer present
            for oldTrip in trips {
                let matchingNewTrips = newTripList.filter( { (t:AnnotatedTrip) -> Bool in
                    return t.trip.id == oldTrip.trip.id
                })
                if matchingNewTrips.isEmpty {
                    oldTrip.trip.deregisterPushNotifications()
                }
            }
        }

        trips =  newTripList
        
        // (Re)register for push notifications
        registerForPushNotifications()
        
        // Clear and refresh notifications to ensure there are no notifications from
        // "deleted" trips or trip elements.
        UIApplication.shared.cancelAllLocalNotifications()
        refreshNotifications()
        
        // Set application badge
        UIApplication.shared.applicationIconBadgeNumber = changes()
    }
    
    
    // Load from keyed archive
    func loadFromArchive(_ path:String) {
        let newTripList = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [AnnotatedTrip]
        trips = newTripList ?? [AnnotatedTrip]()
    }


    func saveToArchive(_ path:String) {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(trips, toFile: path)
        if !isSuccessfulSave {
            print("Failed to save trips...")
        } else {
            print("Trips saved to iOS keyed archive")
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
    
    
    func clear() {
        deregisterPushNotifications()

        // Empty list and cancel all notifications
        trips = [AnnotatedTrip]()
        UIApplication.shared.cancelAllLocalNotifications()
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
