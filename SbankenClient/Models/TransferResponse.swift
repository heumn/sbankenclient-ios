//
//  TransferResponse.swift
//  SbankenClient
//
//  Created by Øyvind Tjervaag on 27/11/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

import Foundation

public class TransferResponse: Codable {
    public var errorType: Int?
    public var isError: Bool
    public var errorMessage: String?
}
