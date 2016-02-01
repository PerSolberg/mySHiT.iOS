//
//  Constant.swift
//  mySHiT
//
//  Created by Per Solberg on 2016-01-20.
//  Copyright © 2016 Per Solberg. All rights reserved.
//

//import Foundation
struct Constant {
    static let test = "id"
    
    // REST service
    struct REST {
        static let baseUrl = ""
    }

    // JSON tags
    struct JSON {
        static let queryCount = "count"
        static let queryResults = "results"
        static let queryError = "error"
        
        static let userFullName = "fullName"
        static let userCommonName = "commonName"
        static let tripId = "id"
        static let tripStartDate = "startDate"
        static let tripEndDate = "endDate"
        static let tripDescription = "description"
        static let tripCode = "code"
        static let tripName = "name"
        static let tripType = "type"
        static let tripElements = "elements"
        
        static let elementType = "type"
        static let elementSubType = "subType"
        static let elementId = "id"
        static let elementReferences = "references"
        
        static let hotelCheckIn = "checkIn"
        static let hotelCheckOut = "checkOut"
        static let hotelName = "hotelName"
        static let hotelAddress = "address"
        static let hotelPostCode = "postCode"
        static let hotelCity = "city"
        static let hotelPhone = "phone"
        static let hotelTransferInfo = "transferInfo"

        static let transportSegmentId = "segmentId"
        static let transportSegmentCode = "segmentCode"
        static let transportLegNo = "legNo"
        static let transportDeptLocation = "departureLocation"
        static let transportDeptStop = "departureStop"
        static let transportDeptAddress = "departureAddress"
        static let transportDeptTimezone = "departureTimezone"
        static let transportDeptTime = "departureTime"
        static let transportDeptCoordinates = "departureCoordinates"
        static let transportDeptTerminalCode = "departureTerminalCode"
        static let transportDeptTerminalName = "departureTerminalName"
        static let transportArrLocation = "arrivalLocation"
        static let transportArrStop = "arrivalStop"
        static let transportArrAddress = "arrivalAddress"
        static let transportArrTimezone = "arrivalTimezone"
        static let transportArrTime = "arrivalTime"
        static let transportArrCoordinates = "arrivalCoordinates"
        static let transportArrTerminalCode = "arrivalTerminalCode"
        static let transportArrTerminalName = "arrivalTerminalName"
        static let transportRouteNo = "routeNo"
        static let transportCompany = "company"
        static let transportCompanyPhone = "companyPhone"

        static let airlineCompanyCode = "companyCode"
    }
    
    // User interface messages
    struct msg {
        static let retrievingTrips = "Retrieving your trips from SHiT"
        static let tripAlertMessage = "SHiT trip '%@' starts in %@ (%@)"
        static let transportAlertMessage = "%@ departs in %@, at %@"
        static let noDetailsAvailable = "No details available yet"
        static let networkUnavailable = "Network unavailable, please refresh when network is available again"
        static let connectError = "Error connecting to SHiT, please check your Internet connection"
        static let connectErrorTitle = "Connection Error"
        static let connectErrorText = "Could not connect to SHiT, please check your Internet connection"
        static let logonFailureTitle = "Logon failed"
        static let logonFailureText = "Please check your user name and password"
        static let alertBoxTitle = "Alert"
        static let noTrips = "You have no SHiT trips yet"
        static let unknownElement = "SHiT, we're sorry but the app doesn't recognise this kind of trip element, hence we cannot present the information nicely but here is a dump of what was received from the server."
        
    }
    
    // Notifications
    struct notification {
        static let networkError = "networkError"
        static let tripElementsRefreshed = "dataRefreshed"
        static let tripsRefreshed = "dataRefreshed"
        static let logonSuccessful = "logonSuccessful"
        static let logonFailed = "logonFailed"
        static let refreshTripList = "RefreshTripList"    
    }
    
    struct segue {
        static let showFlightInfo = "showFlightInfoSegue"
        static let showHotelInfo = "showHotelInfoSegue"
        static let showScheduledTransport = "showScheduledTransportInfoSegue"
        static let showPrivateTransport = "showPrivateTransportInfoSegue"
        static let logout = "logoutSegue"
        static let showTripDetails = "tripDetails"
    }
}

