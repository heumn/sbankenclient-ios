//
//  Result.swift
//  SbankenClient
//
//  Created by Nikolai Heum on 23.04.2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

import Foundation

public enum Result<Value, SbankenError> {
    case success(Value)
    case failure(SbankenError)
}
