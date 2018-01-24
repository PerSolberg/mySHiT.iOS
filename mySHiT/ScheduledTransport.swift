//
//  ScheduledTransport.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-01.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ScheduledTransport: GenericTransport {
    // MARK: Properties
    override var title: String? {
        return (companyName ?? "XX") + " " + (routeNo ?? "***") + ": " + (departureLocation ?? "<Departure>") + " - " + (arrivalLocation ?? "<Arrival>")
    }
    override var startInfo: String? {
        let timeInfo = startTime(dateStyle: .none, timeStyle: .short)
        let airportName = departureStop ?? "<Departure Station>"
        let terminalInfo = (departureTerminalCode != nil && departureTerminalCode != "" ? " [" + departureTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var endInfo: String? {
        let timeInfo = endTime(dateStyle: .none, timeStyle: .short)
        let airportName = arrivalStop ?? "<Arrival Station>"
        let terminalInfo = (arrivalTerminalCode != nil && arrivalTerminalCode != "" ? " [" + arrivalTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var detailInfo: String? {
        if let references = references {
            var refList: String = ""
            for ref in references {
                refList = refList + (refList == "" ? "" : ", ") + ref[TripElement.RefTag_Type]! + ": " + ref[TripElement.RefTag_RefNo]!
            }
            return refList
        }
        return nil
    }
    
    // MARK: NSCoding
    
    // MARK: Initialisers
    
    // MARK: Methods
    override func setNotification() {
        // First delete any existing notifications for this trip element (either one or two)
        cancelNotifications()

        // Set notification (if we have a start date)
        if (tense ?? .past) == .future {
            let defaults = UserDefaults.standard
            let departureLeadtime = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
            let legLeadtime = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
            
            let genericAlertMessage = NSLocalizedString(Constant.msg.transportAlertMessage, comment: "Some dummy comment")
            
            if departureLeadtime > 0 && legNo == 1 {
                setNotification(notificationType: Constant.Settings.deptLeadTime, leadTime: departureLeadtime, alertMessage: genericAlertMessage, userInfo: nil)
            }
            if legLeadtime > 0 {
                setNotification(notificationType: Constant.Settings.legLeadTime, leadTime: legLeadtime, alertMessage: genericAlertMessage, userInfo: nil)
            }
        } else {
            //print("Not setting notifications for past trip element \(id)")
        }
    }

    
    override func viewController(trip:AnnotatedTrip, element:AnnotatedTripElement) -> UIViewController? {
        guard element.tripElement == self else {
            fatalError("Inconsistent trip element and annotated trip element")
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ScheduledTransportDetailsViewController")
        if let stvc = vc as? ScheduledTransportDetailsViewController {
            stvc.tripElement = element
            stvc.trip = trip
            return stvc
        }
        return nil
    }
}
