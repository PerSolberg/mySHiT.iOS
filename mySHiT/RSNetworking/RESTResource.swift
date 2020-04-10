//
//  RESTResource.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-04-07.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation

class RESTResource/*: NSObject*/ {
    typealias Selector = String //(selector: String?, key: String?)

    static let urlSep = "/"
    static let defaultSchema = "https"

    var baseURL : URLComponents
    var selectors : [Selector]?

    
    var url: URLComponents {
        if let selectors = selectors, selectors.count > 0 {
            let selectorPath = selectors.joined(separator: RESTResource.urlSep)
            var fullURL = URLComponents(url: baseURL.url!, resolvingAgainstBaseURL: true)!
            fullURL.path = fullURL.path + RESTResource.urlSep + selectorPath
            return fullURL
        } else {
            return baseURL
        }
    }

    
    init(scheme: String, host: String,  basePath: String?, selectors: [Selector]?, parameters: [URLQueryItem]?) {
        self.selectors = selectors
        baseURL = URLComponents()
        baseURL.scheme = scheme
        baseURL.host = host
        if let path = basePath {
            baseURL.path = path
        }
        baseURL.queryItems = parameters
    }

    
    convenience init(scheme: String, host: String, basePath: String?, parameters: [URLQueryItem]?) {
        self.init(scheme: scheme, host: host, basePath: basePath, selectors: nil, parameters: parameters)
    }


    convenience init(scheme: String, host: String, basePath: String?, selectors: [Selector]?) {
        self.init(scheme: scheme, host: host, basePath: basePath, selectors: selectors, parameters: nil)
    }


    convenience init(host: String, basePath: String?, parameters: [URLQueryItem]?) {
        self.init(scheme: RESTResource.defaultSchema, host: host, basePath: basePath, parameters: parameters)
    }


    convenience init(scheme: String, host: String, basePath: String?) {
        self.init(scheme: scheme, host: host, basePath: basePath, parameters: nil)
    }


    convenience init(host: String, basePath: String?) {
        self.init(scheme: RESTResource.defaultSchema, host: host, basePath: basePath)
    }


    convenience init(host: String, basePath: String?, selectors: [Selector]) {
        self.init(scheme: RESTResource.defaultSchema, host: host, basePath: basePath, selectors: selectors)
    }


    convenience init(host: String, basePath: String?, selectors: [Selector], parameters: [URLQueryItem]) {
        self.init(scheme: RESTResource.defaultSchema, host: host, basePath: basePath, selectors: selectors, parameters: parameters)
    }


    convenience init(host: String, basePath: String?, parameters: [URLQueryItem]) {
        self.init(scheme: RESTResource.defaultSchema, host: host, basePath: basePath, selectors: nil, parameters: parameters)
    }

}
