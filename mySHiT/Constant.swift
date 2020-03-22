//
//  Constant.swift
//  mySHiT
//
//  Created by Per Solberg on 2016-01-20.
//  Copyright © 2016 Per Solberg. All rights reserved.
//

//import Foundation
import UIKit

struct Constant {
    static let test = "id"
    static let deviceType = "iOS"
    
    static let dummyLocalisationComment = "Dummy comment"
    static let emptyString = ""
    
    static let timezoneNameUTC = "UTC"
    static let timezoneUTC = TimeZone(identifier: timezoneNameUTC)
    
    struct alert {
        static let actionOK = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    }
    
    // REST service
    struct REST {
        struct mySHiT {
            static let baseUrl = "https://www.shitt.no/mySHiT/v2"
            struct Resource {
                static let trip = "trip"
                static let thread = "thread"
                static let user = "user"
            }

            struct Param {
                static let userName = "userName"
                static let password = "password"
                //static let sectioned = "sectioned"
                //static let details = "details"
            }

            struct ParamValue {
                //static let sectioned = "1"
                //static let unsectioned = "0"
                //static let detailsNonHistoric = "non-historic"
            }
            
            struct ResultValue {
                static let contentList = "list"
                static let contentDetails = "details"
            }
        }
    }

    // JSON tags
    struct JSON {
        static let queryCount = "count"
//        static let queryResults = "results"
        static let queryError = "error"
        static let queryTripList = "trips"
//        static let queryTripDetails = "tripDetails"
        static let queryContent = "content"
        
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

        static let srvTS = "timestamp"
        static let srvTSFormatted = "formatted"
        static let srvTSEpoch = "epoch"
        static let srvTSEpochSec = "sec"
        static let srvTSEpochMicrosec = "microsec"
    }
    
    // User interface messages
    struct msg {
        static let retrievingTrips = "Retrieving your trips from SHiT"
//        static let retrievingTripDetails = "Retrieving trip details from SHiT"
        static let retrievingTripDetails = NSLocalizedString("Retrieving trip details from SHiT", comment: Constant.dummyLocalisationComment)
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
        static let unableToDisplayElement = "SHiT, we're sorry but there was an unexpected error displaying this element."
        static let chatMsgSeenByOne = "CHAT.SEEN_BY.ONE"
        static let chatMsgSeenByTwoOrMore = "CHAT.SEEN_BY.TWO_OR_MORE"
        static let chatMsgSeenByEveryone = "CHAT.SEEN_BY.ALL"
        static let retrievingChatThread = "CHAT.BCKGND.LOADING"
        static let chatNtfIgnoreAction = "CHAT.NTF.IGNORE"
        static let chatNtfReplyAction = "CHAT.NTF.REPLY"
        static let chatNtfReplySend = "CHAT.NTF.REPLY.SEND"
        static let shortcutSendMessageSubtitle = NSLocalizedString("Send message to participants", comment: Constant.dummyLocalisationComment)
    }
    
    // Notifications
    struct notification {
        static let networkError = NSNotification.Name(rawValue: "networkError")
        static let dataRefreshed = NSNotification.Name(rawValue: "dataRefreshed")
        static let logonSuccessful = NSNotification.Name(rawValue: "logonSuccessful")
        static let logonFailed = NSNotification.Name(rawValue: "logonFailed")
        static let refreshTripList = NSNotification.Name(rawValue: "RefreshTripList")
        static let refreshTripElements = NSNotification.Name(rawValue: "RefreshTripElements")
        static let chatRefreshed = NSNotification.Name(rawValue: "chatRefreshed")
    }

    struct ntfCategory {
        static let newChatMessage = "NTF.INSERT.CHATMESSAGE"
    }

    struct ntfAction {
        static let replyToChatMessage = "REPLY.CHAT.MSG"
        static let ignoreChatMessage = "IGNORE.CHAT.MSG"
    }
    
//    struct ntfUserInfo {
//        static let tripId = "tripId"
//        static let tripElementId = "tripElementID"
//        static let timeZone = "timeZone"
//        static let leadTimeType = "leadTimeType"        
//        static let changeType = "changeType"
//        static let changeOp = "changeOperation"
//        static let fromUserId = "fromUserId"
//    }
    
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
    
    // Shortcuts
    struct shortcut {
        static let chat = "Chat"
    }

    // Icons
    struct icon {
        static let chat = "Chat"
    }

    // Firebase Cloud Messaging (FCM)
    struct Firebase {
        // No longer needed, format changed from "/topics/xxx" to "xxx"
        private static let topicRoot = "/topics"
        
        // These are ready to use as is
        //static let topicGlobal = "\(topicRoot)/GLOBAL"
        static let topicGlobal = "GLOBAL"
        
        // These should be suffixed with IDs
        static let topicRootItinerary = "I-"
        static let topicRootTrip = "T-"
        static let topicRootUser = "U-"
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

