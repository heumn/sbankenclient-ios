//
//  AccessTokenManager.swift
//  SbankenClient
//
//  Created by Terje Tjervaag on 09/10/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

import Foundation

public class AccessTokenManager {

    private var _token: AccessToken?
    
    var token: AccessToken? {

        get {

            guard _token?.expiryDate ?? Date.distantPast < Date() else {
                return nil
            }
            
            return _token
        }

        set(token) {
            _token = token
        }
    }
}
