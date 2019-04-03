//
//  Data+JSON.swift
//  SbankenClient
//
//  Created by Nikolai Heum on 03.04.2019.
//  Copyright © 2019 SBanken. All rights reserved.
//

import Foundation

extension Data {

    var json: [String: AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: AnyObject]
        } catch _ {}

        return nil
    }
}
