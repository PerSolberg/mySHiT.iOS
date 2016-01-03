//
//  TripList.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-27.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class TripList:NSObject, SequenceType, NSCoding {
    //typealias Index = Array<AnnotatedTrip>.Index
    typealias Index = Int
    //typealias SubSequence = Array<AnnotatedTrip>.SubSequence
    //typealias SubSequence = ArraySlice<AnnotatedTrip>
    //typealias Element = AnnotatedTrip
    
    static let sharedList = TripList()
    
    // Prevent other classes from instantiating - User is singleton!
    override private init () {
    }

    required init?( coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        trips  = aDecoder.decodeObjectForKey(PropertyKey.tripsKey) as! [AnnotatedTrip]
    }

    // Public properties
    
    // Private properties
    private var trips: [AnnotatedTrip]! = [AnnotatedTrip]()
    private var rsRequest: RSTransactionRequest = RSTransactionRequest()
    private var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.GET, baseURL: "https://www.shitt.no/mySHiT", path: "trip", parameters: ["userName":"dummy@default.com","password":"******"])


    private struct PropertyKey {
        static let tripsKey = "trips"
    }


    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(trips, forKey: PropertyKey.tripsKey)
    }

    // MARK: SequenceType
    func generate() -> AnyGenerator<AnnotatedTrip> {
        // keep the index of the next trip in the iteration
        var nextIndex = 0
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next car in the iteration
        return anyGenerator {
            if (nextIndex >= self.trips.count) {
                return nil
            }
            return self.trips[nextIndex++]
        }
    }


    func reverse() -> AnyGenerator<AnnotatedTrip> {
        // keep the index of the next trip in the iteration
        var nextIndex = trips.count-1
        
        // Construct a AnyGenerator<AnnotatedTrip> instance, passing a closure that returns the next car in the iteration
        return anyGenerator {
            if (nextIndex < 0) {
                return nil
            }
            return self.trips[nextIndex--]
        }
    }
    
    
    var indices:Range<Int> {
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
    var count: Index.Distance {
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
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransGetTripList.parameters = [ "userName":userCred.name!,
            "password":userCred.urlsafePassword!,
            "sectioned":"0",
            "details":"non-historic"]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : NSURLResponse!, responseDictionary: NSDictionary!, error: NSError!) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.description)")
                NSNotificationCenter.defaultCenter().postNotificationName("networkError", object: self)
            } else if let error = responseDictionary["error"] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NSNotificationCenter.defaultCenter().postNotificationName("networkError", object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                let serverData = responseDictionary["results"] as! NSArray
                self.copyServerData(serverData)
                print("TripList: Server data received, notifying view controllers")
                NSNotificationCenter.defaultCenter().postNotificationName("dataRefreshed", object: self)

            }
        })
        return
    }
    
    
    // Copy data received from server to memory structure
    private func copyServerData(serverData: NSArray!) {
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
                } else {
                    newTrip.trip.compareTripElements(matchingOldTrips[0].trip)
                    if !newTrip.trip.isEqual(matchingOldTrips[0].trip) {
                        newTrip.modified = .Changed
                    }
                }
            }
        }

        trips =  newTripList
    }
    
    
    // Load from keyed archive
    func loadFromArchive(path:String) {
        let newTripList = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [AnnotatedTrip]
        trips = newTripList ?? [AnnotatedTrip]()
    }


    func saveToArchive(path:String) {
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
        trips = [AnnotatedTrip]()
    }
    
}