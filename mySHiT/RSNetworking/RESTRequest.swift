//
//  RESTRequest.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-04-08.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

enum RequestType:String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

class RESTRequest {
    static let dictKey = "results"
    
    struct ErrorDomain {
        static let http = "HTTP"
    }
    struct HTTPStatus {
        static let httpContinue = 100          // Can't use use "continue"
        static let switchingProtocols = 101
        // Success
        static let ok = 200
        static let created = 201
        static let accepted = 202
        static let nonAuthoritativeInformation = 203
        static let noContent = 204
        static let resetContent = 205
        static let partialContent = 206

        // Redirection
        static let multipleChoices = 300
        static let movedPermanently = 301
        static let found = 302
        static let seeOther = 303
        static let notModified = 304
        static let useProxy = 305
//        static let (Unused) = 306
        static let temporaryRedirect = 307

        // Client error
        static let badRequest = 400
        static let unauthorized = 401
        static let paymentRequired = 402
        static let forbidden = 403
        static let notFound = 404
        static let methodNotAllowed = 405
        static let notAcceptable = 406
        static let proxyAuthenticationRequired = 407
        static let requestTimeout = 408
        static let conflict = 409
        static let gone = 410
        static let lengthRequired = 411
        static let preconditionFailed = 412
        static let requestEntityTooLarge = 413
        static let requestURITooLong = 414
        static let unsupportedMediaType = 415
        static let requestedRangeNotSatisfiable = 416
        static let expectationFailed = 417

        // Server error
        static let internalServerError = 500
        static let notImplemented = 501
        static let badGateway = 502
        static let serviceUnavailable = 503
        static let gatewayTimeout = 504
        static let httpVersionNotSupported = 505
    }
    
    typealias DictionaryCompletionHandler = ((URLResponse?, NSDictionary?, Error?) -> Void)

    static func get(_ resource: RESTResource, parameters: [URLQueryItem]?, handler: @escaping DictionaryCompletionHandler) {
        performRequest(method: .get, resource: resource, parameters: parameters, payload: nil, handler: handler)
    }

    
    static func get(_ resource: RESTResource, handler: @escaping DictionaryCompletionHandler) {
        get(resource, parameters: nil, handler: handler)
    }
    
    
    static func post(_ resource: RESTResource, parameters: [URLQueryItem]?, payload: [String: String]?, handler: @escaping DictionaryCompletionHandler) {
        performRequest(method: .post, resource: resource, parameters: parameters, payload: payload, handler: handler)
    }

    
    static func post(_ resource: RESTResource, payload: [String: String]?, handler: @escaping DictionaryCompletionHandler) {
        post(resource, parameters: nil, payload: payload, handler: handler)
    }
    
    
    static func put(_ resource: RESTResource, parameters: [URLQueryItem]?, payload: [String: String]?, handler: @escaping DictionaryCompletionHandler) {
        performRequest(method: .put, resource: resource, parameters: parameters, payload: payload, handler: handler)
    }

    
    static func put(_ resource: RESTResource, payload: [String: String]?, handler: @escaping DictionaryCompletionHandler) {
        put(resource, parameters: nil, payload: payload, handler: handler)
    }
    
    
    fileprivate static func performRequest(method: RequestType, resource: RESTResource, parameters: [URLQueryItem]?, payload: [String: String]?, handler: @escaping DictionaryCompletionHandler) {
        var urlBuilder = resource.url
        if let reqestParams = parameters {
            if urlBuilder.queryItems == nil {
                urlBuilder.queryItems = parameters
            } else {
                urlBuilder.queryItems! += reqestParams
            }
        }
        let sessionConfiguration = URLSessionConfiguration.default
        
        guard let url = urlBuilder.url else {
            handler(nil, nil, NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfErrorHTTPBadURL.rawValue), userInfo: nil))
            return
        }
        
        var request = URLRequest(url:url)
        request.httpMethod = method.rawValue
        var params = Data()
        if let payload = payload {
            params = try! JSONSerialization.data(withJSONObject: payload, options: .init(rawValue: 0))
        }
        request.httpBody = params
        
        let urlSession = URLSession(configuration:sessionConfiguration, delegate: nil, delegateQueue: nil)
        
        urlSession.dataTask(with: request, completionHandler: {(responseData: Data?, response: URLResponse?, error: Error?) -> Void in
            if error != nil {
                handler(response, nil, error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let httpError = NSError(domain: ErrorDomain.http, code: httpResponse.statusCode, userInfo: nil)
                    handler(response, nil, httpError)
                    return
                }
            }
            
            let resultDictionary = NSMutableDictionary()
            var jsonResponse : Any?
            do {
                jsonResponse  = try JSONSerialization.jsonObject(with: (responseData!), options: [])
            }
            catch let error as NSError {
                handler(response, nil, error)
            }

            if let jsonResponse = jsonResponse as? [String:Any] {
                resultDictionary.setDictionary(jsonResponse)
            } else if let jsonResponse = jsonResponse as? [Any] {
                resultDictionary[RESTRequest.dictKey] = jsonResponse
            }
            handler(response, resultDictionary, error)
        }).resume()
    }


}
