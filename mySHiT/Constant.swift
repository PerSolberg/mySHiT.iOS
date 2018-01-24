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
    static let deviceType = "iOS"
    
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
        static let userShortName = "shortName"
        static let userId = "userId"
        static let userInitials = "initials"
        
        static let tripId = "id"
        static let tripItineraryId = "itineraryId"
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

        static let eventStartTime = "startTime"
        static let eventTravelTime = "travelTime"
        static let eventVenueName = "venueName"
        static let eventVenueAddress = "venueAddress"
        static let eventVenuePostCode = "venuePostCode"
        static let eventVenueCity = "venueCity"
        static let eventVenuePhone = "venuePhone"
        static let eventAccessInfo = "accessInfo"
        static let eventTimezone = "timezone"

        static let messageList = "messages"
        static let messageLastSeenByOthers = "lastSeenByOthers"
        static let messageLastSeenByMe = "lastSeenByMe"
        static let messageVersion = "messageVersion"
        static let lastSeenVersion = "lastSeenVersion"

        static let msgId = "id"
        static let msgUserId = "userId"
        static let msgUserName = "userName"
        static let msgUserInitials = "userInitials"
        static let msgDeviceType = "deviceType"
        static let msgDeviceId = "deviceId"
        static let msgLocalId = "localId"
        static let msgText = "message"
        static let msgStoredTS = "storedTS"
        static let msgCreatedTS = "createdTS"

    }
    
    // User interface messages
    struct msg {
        static let retrievingTrips = "Retrieving your trips from SHiT"
        static let tripAlertMessage = "SHiT trip '%@' starts in %@ (%@)"
        static let transportAlertMessage = "%@ departs in %@, at %@"
        static let eventAlertMessage = "%@ starts in %@, at %@"
        static let noDetailsAvailable = "No details available yet"
        static let networkUnavailable = "Network unavailable, please refresh when network is available again"
        static let connectError = "Error connecting to SHiT, please check your Internet connection"
        static let connectErrorTitle = "Connection Error"
        static let connectErrorText = "Could not connect to SHiT, please check your Internet connection"
        static let logonFailureTitle = "Logon failed"
        static let logonFailureText = "Please check your user name and password"
        static let alertBoxTitle = "Alert"
        static let noTrips = "You have no SHiT trips yet"
        static let noMessages = "CHAT.BCKGND.NOMSG"
        static let unknownElement = "SHiT, we're sorry but the app doesn't recognise this kind of trip element, hence we cannot present the information nicely but here is a dump of what was received from the server."
        static let chatMsgSeenByOne = "CHAT.SEEN_BY.ONE"
        static let chatMsgSeenByTwoOrMore = "CHAT.SEEN_BY.TWO_OR_MORE"
        static let chatMsgSeenByEveryone = "CHAT.SEEN_BY.ALL"
        static let retrievingChatThread = "CHAT.BCKGND.LOADING"
        static let chatNtfIgnoreAction = "CHAT.NTF.IGNORE"
        static let chatNtfReplyAction = "CHAT.NTF.REPLY"
        static let chatNtfReplySend = "CHAT.NTF.REPLY.SEND"
    }
    
    // Notifications
    struct notification {
        static let networkError = "networkError"
        static let tripElementsRefreshed = "dataRefreshed"
        static let tripsRefreshed = "dataRefreshed"
        static let logonSuccessful = "logonSuccessful"
        static let logonFailed = "logonFailed"
        static let refreshTripList = "RefreshTripList"
        static let refreshTripElements = "RefreshTripElements"
        static let chatRefreshed = "chatRefreshed"
    }

    struct notificationCategory {
        static let newChatMessage = "NTF.INSERT.CHATMESSAGE"
    }

    struct notificationAction {
        static let replyToChatMessage = "REPLY.CHAT.MSG"
        static let ignoreChatMessage = "IGNORE.CHAT.MSG"
    }
    
    struct notificationUserInfo {
        static let tripId = "TripID"
        static let tripElementId = "TripElementID"
        static let timeZone = "TimeZone"
        static let leadTimeType = "leadTimeType"
    }
    
    struct changeType {
        static let chatMessage = "CHATMESSAGE"
        static let trip = "TRIP"
        static let itinerary = "ITINERARY"
        static let user = "USER"
    }
    
    struct changeOperation {
        static let insert = "INSERT"
        static let update = "UPDATE"
        static let delete = "DELETE"
    }
    
    // Firebase Cloud Messaging (FCM)
    struct Firebase {
        private static let topicRoot = "/topics"
        
        // These are ready to use as is
        static let topicGlobal = "\(topicRoot)/GLOBAL"
        
        // These should be suffixed with IDs
        static let topicRootItinerary = "\(topicRoot)/I-"
        static let topicRootTrip = "\(topicRoot)/T-"
        static let topicRootUser = "\(topicRoot)/U-"
    }

    struct segue {
        static let showFlightInfo = "showFlightInfoSegue"
        static let showHotelInfo = "showHotelInfoSegue"
        static let showEventInfo = "showEventInfoSegue"
        static let showScheduledTransport = "showScheduledTransportInfoSegue"
        static let showPrivateTransport = "showPrivateTransportInfoSegue"
        static let logout = "logoutSegue"
        static let showTripDetails = "tripDetails"
        static let showChatTable = "showChatTableSegue"
        static let showChatView = "showChatViewSegue"
        static let embedChatTable = "embedChatTableSegue"
    }
    
    struct Settings {
        static let tripLeadTime = "trip_notification_leadtime"
        static let deptLeadTime = "dept_notification_leadtime"
        static let legLeadTime = "leg_notification_leadtime"
        static let eventLeadTime = "event_notification_leadtime"
    }
}

