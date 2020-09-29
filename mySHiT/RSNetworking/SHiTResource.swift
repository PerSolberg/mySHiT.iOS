//
//  SHiTResource.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-04-07.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import os


enum SHiTStatus {
    case ok
    case authenticationFailed
    case communicationError
    case serverError
}

enum SHiTRetry:String {
    case skip = "SKIP"   // Don't retry, just proceed
    case normal = "NORM" // Retry
    case stop = "STOP"   // Don't retry, manually clean up before proceeding
}

typealias SHiTHandledStatus = (status:SHiTStatus, retry: SHiTRetry?)

class SHiTResource: RESTResource {
    
    static let host = "www.shitt.no"
    fileprivate struct Path {
        static let Base = "/mySHiT/v2"
        static let Thread = SHiTResource.Path.Base + RESTResource.urlSep + "thread"
        static let User = SHiTResource.Path.Base + RESTResource.urlSep + "user"
        static let Trip = SHiTResource.Path.Base + RESTResource.urlSep + "trip"
    }
    
    // REST service
    struct Param {
        static let userName = "userName"
        static let password = "password"
        static let lastMessageId = "lastMessageId"
    }
    struct Verb {
        static let read = "read"
    }
    struct Result {
        static let contentList = "list"
        static let contentDetails = "details"
    }

    static func tripList(parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.Path.Trip, parameters: credentials()! + parameters)
    }


    static func trip(key: String, parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.Path.Trip, selectors: [key], parameters: credentials()! + parameters )
    }


    static func thread(key: String, parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.Path.Thread, selectors: [key], parameters: credentials()! + parameters )
    }


    static func message(keys: [String], parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.Path.Thread, selectors: keys, parameters: credentials()! + parameters )
    }


    static func user(parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.Path.User, parameters: parameters)
    }

    
    static func checkStatus(response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> SHiTHandledStatus {
        if let error = error {
            if error._domain == RESTRequest.ErrorDomain.http && error._code == RESTRequest.HTTPStatus.unauthorized {
                os_log("Authentication failed", log: OSLog.webService, type: .error)
                NotificationCenter.default.post(name: Constant.Notification.logonFailed, object: self)
                return (.authenticationFailed, .stop)
            } else {
                //If there was an error, log it
                os_log("Communication error : %{public}s", log: OSLog.webService, type: .error,  error.localizedDescription)
                NotificationCenter.default.post(name: Constant.Notification.networkError, object: self)
                return (.communicationError, nil)
            }
        } else if let responseDictionary = responseDictionary, let error = responseDictionary[Constant.JSON.errorMsg] {
            let errMsg = error as? String ?? Constant.Message.requestServerErrorUnavailable
            os_log("Server error : %{public}s", log: OSLog.webService, type: .error,  errMsg)
            NotificationCenter.default.post(name: Constant.Notification.networkError, object: self)
            if let retryModeString = responseDictionary[Constant.JSON.retryMode] as? String {
                return (.serverError, SHiTRetry(rawValue: retryModeString))
            } else {
                return (.serverError, nil)
            }
        }
        return (.ok, nil)
    }

    
    fileprivate static func credentials() -> [URLQueryItem]? {
        let userCred = User.sharedUser.getCredentials()
        guard let userName = userCred.name, let userPassword = userCred.password else {
            return nil
        }
        
        return [ URLQueryItem(name: Param.userName, value: userName), URLQueryItem(name: Param.password, value: userPassword) ]
    }
}
