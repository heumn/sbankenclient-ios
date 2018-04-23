//
//  SbankenError.swift
//  SbankenClient
//
//  Created by Nikolai Heum on 23.04.2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

import Foundation

public enum SbankenError: Error, CustomStringConvertible {

    case missingNetworkResponse
    case unableToDecodeNetworkResponse
    case message(String)
    case generic(Error)

    public var description: String {
        switch self {
        case .missingNetworkResponse:
            return "Sbanken svarer ikke med forventet data"
        case .unableToDecodeNetworkResponse:
            return "Unable to decode network response"
        case let .message(message):
            return message
        case let .generic(error):
            return (error as CustomStringConvertible).description
        }
    }

    init(_ message: String) {
        self = .message(message)
    }

    init(_ error: Error) {
        if let error = error as? SbankenError {
            self = error
        } else {
            self = .generic(error)
        }
    }
}
