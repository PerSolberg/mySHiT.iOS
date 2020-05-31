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
                    let httpError = NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: nil)
                    handler(response, nil, httpError)
                    return
                }
            }
            
            let resultDictionary = NSMutableDictionary()
            var jsonResponse : Any?
            do {
//              options: JSONSerialization.ReadingOptions.allowFragments
                jsonResponse  = try JSONSerialization.jsonObject(with: (responseData!), options: [])
            }
            catch let error as NSError {
//                let errMsg = "A JSON parsing error occurred:\n\(error)\n\(String(describing: responseData))"
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
