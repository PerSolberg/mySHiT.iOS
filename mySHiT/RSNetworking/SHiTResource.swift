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
    fileprivate static let basePath = "/mySHiT/v2"
    
    // REST service
    struct Param {
        static let userName = "userName"
        static let password = "password"
    }
    struct Verb {
        static let read = "read"
    }
    struct Result {
        static let contentList = "list"
        static let contentDetails = "details"
    }

    static func tripList(parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.basePath + RESTResource.urlSep + "trip", parameters: credentials()! + parameters)
    }


    static func trip(key: String, parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.basePath + RESTResource.urlSep + "trip", selectors: [key], parameters: credentials()! + parameters )
    }


    static func thread(key: String, parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.basePath + RESTResource.urlSep + "thread", selectors: [key], parameters: credentials()! + parameters )
    }


    static func message(keys: [String], parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.basePath + RESTResource.urlSep + "thread", selectors: keys, parameters: credentials()! + parameters )
    }


    static func user(parameters: [URLQueryItem]) -> RESTResource {
        return RESTResource(host: SHiTResource.host, basePath: SHiTResource.basePath + RESTResource.urlSep + "user", parameters: parameters)
    }

    
    static func checkStatus(response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> SHiTHandledStatus {
        if let error = error {
            if error._domain == "HTTP" && error._code == 401 {
                os_log("Authentication failed", log: OSLog.webService, type: .error)
                NotificationCenter.default.post(name: Constant.notification.logonFailed, object: self)
                return (.authenticationFailed, .stop)
            } else {
                //If there was an error, log it
                os_log("Communication error : %{public}s", log: OSLog.webService, type: .error,  error.localizedDescription)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
                return (.communicationError, nil)
            }
        } else if let responseDictionary = responseDictionary, let error = responseDictionary[Constant.JSON.errorMsg] {
            let errMsg = error as? String ?? "Unable to retrieve server error message"
            os_log("Server error : %{public}s", log: OSLog.webService, type: .error,  errMsg)
            NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
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
        guard let userName = userCred.name else {
            return nil
        }
        guard let userPassword = userCred.password else {
            return nil
        }
        
        return [ URLQueryItem(name: Param.userName, value: userName), URLQueryItem(name: Param.password, value: userPassword) ]
    }
}
