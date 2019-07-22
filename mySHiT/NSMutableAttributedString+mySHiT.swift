//
//  NSMutableAttributedString+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-07-21.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import os

extension NSMutableAttributedString {
    func addLink(for matchText: String, prefix: String, options: NSRegularExpression.Options = []) {
        addLink(for: matchText, options: options) { match -> String in
            return prefix + match
        }
    }

    func addLink(for matchText: String, options: NSRegularExpression.Options = [], transform: (String) -> String? = {return $0} ) {
        guard let regex = try? NSRegularExpression(pattern: matchText, options: options) else { return };
        addLink(for: regex, transform: transform)
    }
    
    func addLink(for matchExp: NSRegularExpression, transform: (String) -> String? = {return $0} ) {
        let matches = matchExp.matches(in: string, range: NSRange(string.startIndex..., in: string))
        for match in matches {
            if let matchRange = Range(match.range, in: self.string) {
                let matchText = String(self.string[matchRange])
                if let linkValue = transform(matchText), let linkUrl = URL(string: linkValue) {
                    self.addAttribute(NSAttributedString.Key.link, value: linkUrl, range: match.range)
                } else {
                    os_log("Cannot transform matched text to valid URL: '%{public}s'", log: OSLog.general, type: .error, matchText)
                }
            } else {
                os_log("Invalid range in regex matches", log: OSLog.general, type: .error)
            }
        }
    }
    
    func setAttributes(_ attrs: [NSAttributedString.Key : Any]?) {
        let nsRange = NSRange(string.startIndex..., in: string)
        setAttributes(attrs, range: nsRange)
    }
}
