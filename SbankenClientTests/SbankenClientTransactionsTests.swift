//
//  SbankenClientTests.swift
//  SbankenClientTests
//
//  Created by Terje Tjervaag on 07/10/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

import XCTest
@testable import SbankenClient

class SbankenClientTransactionsTests: XCTestCase {
    var mockUrlSession = MockURLSession()
    var mockTokenManager = AccessTokenManager()
    var defaultUserId = "12345"
    var defaultAccountNumber = "97100000000"
    var defaultAccessToken: AccessToken = AccessToken("TOKEN", expiresIn: 1000, tokenType: "TYPE")
    var client: SbankenClient?

    var goodTransactionsData = """
    {
    "availableItems": 2,
    "items": [{
            "transactionId": "0",
            "accountingDate": "2018-03-17T00:00:00+01:00",
            "interestDate": "2018-03-17T00:00:00+01:00",
            "otherAccountNumberSpecified": false,
            "amount": -10.000,
            "text": "VISA",
            "transactionType": "Bekreftet VISA",
            "transactionTypeCode": 946,
            "transactionTypeText": "",
            "isReservation": true,
            "cardDetailsSpecified": false
        },
        {
            "transactionId": "43465574623452563456",
            "accountingDate": "2018-03-13T00:00:00+01:00",
            "interestDate": "2018-03-13T00:00:00+01:00",
            "otherAccountNumberSpecified": false,
            "amount": -149.000,
            "text": "*0923 09.03 NOK 149.00 ITUNES.COM/BILL Kurs: 1.0000",
            "transactionType": "VISA VARE",
            "transactionTypeCode": 714,
            "transactionTypeText": "VISA VARE",
            "isReservation": false,
            "reservationType": null,
            "source": 1,
            "cardDetails": {
                "cardNumber": "*0123",
                "currencyAmount": 149.000,
                "currencyRate": 1.00000,
                "merchantCategoryCode": "5735",
                "merchantCategoryDescription": "Musikk",
                "merchantCity": "ITUNES.COM/BI",
                "merchantName": "ITUNES.COM/BILL",
                "originalCurrencyCode": "NOK",
                "purchaseDate": "2018-03-09T00:00:00+01:00",
                "transactionId": "1234655513452435645"
            },
            "cardDetailsSpecified": true
        }]
    }
    """.data(using: .utf8)

    var badTransactionsData = """
        {tralala
    """.data(using: .utf8)

    override func setUp() {
        super.setUp()
        mockTokenManager.token = defaultAccessToken
        client = SbankenClient(clientId: "CLIENT",
                               secret: "SECRET",
                               tokenManager: mockTokenManager,
                               urlSession: mockUrlSession)
        mockUrlSession.lastRequest = nil
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testClientQueriesForTransactions() {
        let request = transactionRequest(userId: defaultUserId, accountNumber: defaultAccountNumber)

        XCTAssertEqual(request?.url?.path, "/Bank/api/v2/Transactions/\(defaultUserId)/\(defaultAccountNumber)")
    }

    func testTransactionRequestHasRequiredHeaders() {
        let request = transactionRequest(userId: defaultUserId, accountNumber: defaultAccountNumber)

        XCTAssertEqual(request?.allHTTPHeaderFields!["Authorization"], "Bearer \(defaultAccessToken.accessToken)")
        XCTAssertEqual(request?.allHTTPHeaderFields!["Accept"], "application/json")
    }

    func testTransactionRequestReturnsNilForInvalidUrl() {
        let request = transactionRequest(userId: "|", accountNumber: defaultAccountNumber)

        XCTAssertNil(request)
    }

    func testTransactionRequestReturnsErrorForBadData() {
        mockUrlSession.responseData = badTransactionsData
        var error = false
        _ = transactionRequest(userId: defaultUserId,
                               accountNumber: defaultAccountNumber,
                               success: { _ in },
                               failure: { (returnedError) in error = true })

        XCTAssertTrue(error)
    }

    func testAccountRequestReturnsSuccessForGoodData() {
        mockUrlSession.responseData = goodTransactionsData
        var response: TransactionResponse?
        var error = false
        _ = transactionRequest(userId: defaultUserId,
                               accountNumber: defaultAccountNumber,
                               success: { (transactionResponse) in response = transactionResponse },
                               failure: { (returnedError) in error = true })

        XCTAssertFalse(error)
        XCTAssertNotNil(response)
    }

    func testAccountRequestReturnsErrorForHttpError() {
        mockUrlSession.responseError = NSError(domain: "error", code: 0, userInfo: nil)
        var error: Error?
        _ = transactionRequest(userId: defaultUserId,
                               accountNumber: defaultAccountNumber,
                               success: { _ in },
                               failure: { (returnedError) in error = returnedError })

        XCTAssertNotNil(error)
    }

    func transactionRequest(userId: String,
                            accountNumber: String,
                            success: @escaping (TransactionResponse) -> Void = {_ in },
                            failure: @escaping (Error?) -> Void = {_ in }) -> URLRequest? {
        client?.transactions(userId: userId,
                             accountNumber: "97100000000",
                             startDate: Date(),
                             endDate: Date(),
                             index: 0,
                             length: 10) { result in
                                
                                switch result {
                                case .success(let response):
                                    success(response)
                                case .failure(let error):
                                    failure(error)
                                }
        }

        return mockUrlSession.lastRequest
    }
}

