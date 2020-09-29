//
//  ScheduledTransport.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-01.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

class ScheduledTransport: GenericTransport {
    struct Format {
        static let TitleRouteOnly = NSLocalizedString("FMT.TRANSPORT.TITLE.ROUTE", comment:"")
        static let TitleLocationOnly = NSLocalizedString("FMT.TRANSPORT.TITLE.LOCATION", comment:"")
        static let TitleRouteAndLocation = NSLocalizedString("FMT.TRANSPORT.TITLE.ROUTE_AND_LOCATION", comment:"")

        static let StopTimeOnly = NSLocalizedString("FMT.TRANSPORT.STOP.TIME", comment:"")
        static let StopNameOnly = NSLocalizedString("FMT.TRANSPORT.STOP.NAME", comment:"")
        static let StopTimeAndName = NSLocalizedString("FMT.TRANSPORT.STOP.TIME_AND_NAME", comment:"")
    }
    
    //
    // MARK: Properties
    //
    override var title: String? {
        switch (routeName, locationInfo) {
        case (nil, nil):
            return nil
        case (nil, let locationInfo?):
            return String.localizedStringWithFormat(Format.TitleLocationOnly, locationInfo)
        case (let routeName?, nil):
            return String.localizedStringWithFormat(Format.TitleRouteOnly, routeName)
        case (let routeName?, let locationInfo?):
            return String.localizedStringWithFormat(Format.TitleRouteAndLocation, routeName, locationInfo)
        }
    }
    override var startInfo: String? {
        switch (startTime(dateStyle: .none, timeStyle: .short), departureStopInfo) {
        case (nil, nil):
            return nil
        case (nil, let stopInfo?):
            return String.localizedStringWithFormat(Format.StopNameOnly, stopInfo)
        case (let timeInfo?, nil):
            return String.localizedStringWithFormat(Format.StopTimeOnly, timeInfo)
        case (let timeInfo?, let stopInfo?):
            return String.localizedStringWithFormat(Format.StopTimeAndName, timeInfo, stopInfo)
        }
    }
    override var endInfo: String? {
        switch (endTime(dateStyle: .none, timeStyle: .short), arrivalStopInfo) {
        case (nil, nil):
            return nil
        case (nil, let stopInfo?):
            return String.localizedStringWithFormat(Format.StopNameOnly, stopInfo)
        case (let timeInfo?, nil):
            return String.localizedStringWithFormat(Format.StopTimeOnly, timeInfo)
        case (let timeInfo?, let stopInfo?):
            return String.localizedStringWithFormat(Format.StopTimeAndName, timeInfo, stopInfo)
        }
    }
    override var detailInfo: String? {
        return taggedReferenceList(separator: TripElement.Format.refListSeparator)
    }
    
    
    //
    // MARK: NSCoding
    //
    
    
    //
    // MARK: Initialisers
    //
    
    
    //
    // MARK: Methods
    //
    override func setNotification() {
        // First delete any existing notifications for this trip element (either one or two)
        cancelNotifications()

        // Set notification (if we have a start date)
        if (tense ?? .past) == .future {
            let defaults = UserDefaults.standard
            let departureLeadtime = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
            let legLeadtime = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
            
            if departureLeadtime > 0 && legNo == 1 {
                setNotification(notificationType: Constant.Settings.deptLeadTime, leadTime: departureLeadtime, alertMessage: Constant.Message.transportAlertMessage, userInfo: nil)
            }
            if legLeadtime > 0 {
                setNotification(notificationType: Constant.Settings.legLeadTime, leadTime: legLeadtime, alertMessage: Constant.Message.transportAlertMessage, userInfo: nil)
            }
        }
    }

    
    override func viewController() -> UIViewController? {
        let stvc = ScheduledTransportDetailsViewController.instantiate(fromAppStoryboard: .Main)
        stvc.tripElement = self
        return stvc
    }

}
