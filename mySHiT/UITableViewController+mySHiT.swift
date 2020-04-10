//
//  UITableViewController+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-03-28.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController
{
    func endRefreshing() {
        DispatchQueue.main.async {
            if let refreshControl = self.refreshControl {
                if refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            }
        }
    }
}
