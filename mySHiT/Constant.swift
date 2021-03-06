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
    static let deviceType = "iOS"
    static let deviceTypeDefault = "default"
    static let appName = "mySHiT"
    
    static let emptyString = ""
    static let space = " "
    static let lineFeed = "\n"
    
    static let timezoneNameUTC = "UTC"
    static let timezoneUTC = TimeZone(identifier: timezoneNameUTC)
    
    struct Archive {
        fileprivate static let archiveDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

        static let userURL = archiveDirectory.appendingPathComponent("user")
        static let tripsURL = archiveDirectory.appendingPathComponent("trips")
        static let sectionsURL = archiveDirectory.appendingPathComponent("sections")
    }

    struct Alert {
        static let actionOK = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    }
    
    
    //
    // MARK: Regular Expressions
    //
    struct RegExPattern {
        static let whitespace = "\\s+"
    }

    struct RegEx {
        static let matchAll:NSRegularExpression! = try? NSRegularExpression(pattern: ".+", options: [.dotMatchesLineSeparators])
        static let matchFirstLine:NSRegularExpression! = try? NSRegularExpression(pattern: ".+", options: [])
    }
    
    //
    // MARK: JSON tags
    //
    struct JSON {
        static let status = "status"
        static let errorMsg = "errorMsg"
        static let errorCode = "errorCode"
        static let retryMode = "retryMode"

        static let queryCount = "count"
        static let queryTripList = "trips"
        static let queryUser = "user"
        static let queryContent = "content"
        static let queryMessage = "message"
        
        static let userFullName = "fullName"
        static let userCommonName = "commonName"
        static let userShortName = "shortName"
        static let userId = "userId"
        static let userInitials = "initials"
        
        static let tripId = "id"
        static let tripItineraryId = "itineraryId"
        static let tripStartDate = "startDate"
        static let tripStartTimezone = "startTimezone"
        static let tripEndDate = "endDate"
        static let tripEndTimezone = "endTimezone"
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
        static let hotelTimezone = "timezone"
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
    
    //
    // MARK: User interface messages
    //
    struct Message {
        static let retrievingTrips = NSLocalizedString("Retrieving your trips from SHiT", comment: "")
        static let retrievingTripDetails = NSLocalizedString("Retrieving trip details from SHiT", comment: "")
        static let tripAlertMessage = NSLocalizedString("SHiT trip '%@' starts in %@ (%@)", comment: "")
        static let transportAlertMessage = NSLocalizedString("%@ departs in %@, at %@", comment: "")
        static let eventAlertMessage = NSLocalizedString("%@ starts in %@, at %@", comment: "")
        static let noDetailsAvailable = NSLocalizedString("No details available yet", comment: "")
        static let networkUnavailable = NSLocalizedString("Network unavailable, please refresh when network is available again", comment: "")
        static let connectError = NSLocalizedString("Error connecting to SHiT, please check your Internet connection", comment: "")
        static let connectErrorTitle = NSLocalizedString("Connection Error", comment: "")
        static let connectErrorText = NSLocalizedString("Could not connect to SHiT, please check your Internet connection", comment: "")
        static let logonFailureTitle = NSLocalizedString("Logon failed", comment: "")
        static let logonFailureText = NSLocalizedString("Please check your user name and password", comment: "")
        static let alertBoxTitle = NSLocalizedString("Alert", comment: "")
        static let noTrips = NSLocalizedString("You have no SHiT trips yet", comment: "")
        static let noMessages = NSLocalizedString("CHAT.BCKGND.NOMSG", comment: "")
        static let unknownElement = NSLocalizedString("SHiT, we're sorry but the app doesn't recognise this kind of trip element, hence we cannot present the information nicely but here is a dump of what was received from the server.", comment: "")
        static let unableToDisplayElement = NSLocalizedString("SHiT, we're sorry but there was an unexpected error displaying this element.", comment: "")
        static let chatMsgSeenByOne = NSLocalizedString("CHAT.SEEN_BY.ONE", comment: "")
        static let chatMsgSeenByTwoOrMore = NSLocalizedString("CHAT.SEEN_BY.TWO_OR_MORE", comment: "")
        static let chatMsgSeenByEveryone = NSLocalizedString("CHAT.SEEN_BY.ALL", comment: "")
        static let retrievingChatThread = NSLocalizedString("CHAT.BCKGND.LOADING", comment: "")
        static let chatNtfIgnoreAction = NSLocalizedString("CHAT.NTF.IGNORE", comment: "")
        static let chatNtfReplyAction = NSLocalizedString("CHAT.NTF.REPLY", comment: "")
        static let chatNtfReplySend = NSLocalizedString("CHAT.NTF.REPLY.SEND", comment: "")
        static let shortcutSendMessageSubtitle = NSLocalizedString("Send message to participants", comment: "")

        static let unknownUserName = NSLocalizedString("USER.UNKNOWN.NAME", comment: "")
        static let unknownUserInitials = NSLocalizedString("USER.UNKNOWN.INITIALS", comment: "")

        static let tripElementTitleDefault = NSLocalizedString("TRIPELEMENT.TITLE.DEFAULT", comment: "")
        static let tripElementStartInfoDefault = NSLocalizedString("TRIPELEMENT.STARTINFO.DEFAULT", comment: "")
        static let tripElementDetailsDefault = NSLocalizedString("TRIPELEMENT.DETAILS.DEFAULT", comment: "")
        
        static let hotelTransferInfoDefault = NSLocalizedString("HOTEL.TRANSFERINFO.DEFAULT", comment: "")

        static let transportCompanyNameDefault = NSLocalizedString("TRANSPORT.COMPANY_NAME.DEFAULT", comment: "")
        static let transportCompanyCodeDefault = NSLocalizedString("TRANSPORT.COMPANY_CODE.DEFAULT", comment: "")

        static let alertListNotificationNotFound = NSLocalizedString("ALERTLIST.NOTIFICATION.NOTFOUND", comment: "")
        static let alertListUnknownTime = NSLocalizedString("ALERTLIST.ALERTTIME.UNKNOWN", comment: "")
        
        static let requestServerErrorUnavailable = NSLocalizedString("REST_REQUEST.ERROR.SERVER_MSG_UNAVAILABLE", comment: "")
    }
    
    //
    // MARK: Notifications
    //
    struct Notification {
        static let networkError = NSNotification.Name(rawValue: "networkError")
        static let dataRefreshed = NSNotification.Name(rawValue: "dataRefreshed")
        static let logonSuccessful = NSNotification.Name(rawValue: "logonSuccessful")
        static let logonFailed = NSNotification.Name(rawValue: "logonFailed")
        static let refreshTripList = NSNotification.Name(rawValue: "RefreshTripList")
        static let refreshTripElements = NSNotification.Name(rawValue: "RefreshTripElements")
        static let chatRefreshed = NSNotification.Name(rawValue: "chatRefreshed")
    }

    struct NotificationCategory {
        static let newChatMessage = "NTF.INSERT.CHATMESSAGE"
        static let alertDefault = "SHiT"
    }

    struct NotificationAction {
        static let replyToChatMessage = "REPLY.CHAT.MSG"
        static let ignoreChatMessage = "IGNORE.CHAT.MSG"
    }
    
    struct ChangeType {
        static let chatMessage = "CHATMESSAGE"
        static let trip = "TRIP"
        static let itinerary = "ITINERARY"
        static let user = "USER"
    }
    
    struct ChangeOperation {
        static let insert = "INSERT"
        static let update = "UPDATE"
        static let delete = "DELETE"
    }
    
    //
    // MARK: Shortcuts
    //
    struct Shortcut {
        static let chat = "Chat"
    }

    //
    // MARK: Icons
    //
    struct Icon {
        static let chat = "Chat"
        static let watermarkChanged = UIImage(named: "changed")
        static let watermarkNew = UIImage(named: "new")
    }

    //
    // MARK: Firebase Cloud Messaging (FCM)
    //
    struct Firebase {
        // These are ready to use as is
        static let topicGlobal = "GLOBAL"
        
        // These should be suffixed with IDs
        static let topicRootItinerary = "I-"
        static let topicRootTrip = "T-"
        static let topicRootUser = "U-"
    }

    struct Segue {
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
    
    
    //
    // MARK: Settings
    //
    struct Settings {
        // System
        static let url = Bundle.main.url(forResource: "Root", withExtension: "plist", subdirectory: "Settings.bundle")
        static let preferencesDictionaryKey = "PreferenceSpecifiers"
        static let preferenceIdentifier = "Key"
        static let preferenceDefaultValue = "DefaultValue"

        // Application
        static let upcomingTrips = "upcoming_trips"
        static let tripLeadTime = "trip_notification_leadtime"
        static let deptLeadTime = "dept_notification_leadtime"
        static let legLeadTime = "leg_notification_leadtime"
        static let eventLeadTime = "event_notification_leadtime"
        static let notificationMute = "mute_notification_sound"
        struct MuteInterval {
            static let always = "A"
            static let never = "N"
            static let day = "D"
            static let week = "W"
            static let month = "M"
        }
    }
    
    struct Group {
        static let defaults = "group.no.andmore.mySHiT.defaults"
    }
    
    //
    // MARK: Date Formats
    //
    struct DateFormat {
        static let isoYearToMinuteWithSpace = "yyyy-MM-dd HH:mm"
    }
}

