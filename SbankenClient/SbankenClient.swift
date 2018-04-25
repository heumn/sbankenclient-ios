//
//  SbankenClient.swift
//  SbankenClient
//
//  Created by Terje Tjervaag on 07/10/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

import Foundation

public class SbankenClient {

    private let clientId: String
    private let secret: String

    private let encoder = JSONEncoder()
    private let tokenManager: AccessTokenManager
    private let urlSession: SURLSessionProtocol

    private lazy var decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }()

    public init(clientId: String,
                secret: String,
                tokenManager: AccessTokenManager = AccessTokenManager(),
                urlSession: SURLSessionProtocol = URLSession.shared) {
        self.clientId = clientId
        self.secret = secret
        self.tokenManager = tokenManager
        self.urlSession = urlSession
    }

    public func accounts(userId: String, completion: @escaping (Result<[Account], SbankenError>) -> Void) {

        accessToken(clientId: clientId, secret: secret) { result in

            switch result {
            case .failure(let error):
                completion(.failure(SbankenError(error)))
            case .success(let token):

                let urlString = "\(Constants.baseUrl)/Bank/api/v1/Accounts/\(userId)"
                guard let request = self.urlRequest(urlString, token: token) else {
                    fatalError("Unable to parse API endpoint string")
                }

                self.urlSession.dataTask(with: request, completionHandler: { data, response, error in

                    guard error == nil else {
                        completion(.failure(SbankenError(error)))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.missingNetworkResponse))
                        return
                    }

                    if let accountsResponse = try? self.decoder.decode(AccountsResponse.self, from: data) {
                        completion(.success(accountsResponse.items))
                    } else {
                        completion(.failure(.unableToDecodeNetworkResponse))
                    }

                }).resume()
            }
        }
    }

    public func transactions(userId: String,
                             accountNumber: String,
                             startDate: Date,
                             endDate: Date = Date(),
                             index: Int = 0,
                             length: Int = 10,
                             completion: @escaping (Result<TransactionResponse, SbankenError>) -> Void) {

        accessToken(clientId: clientId, secret: secret) { result in

            switch result {
            case .failure(let error):
                completion(.failure(SbankenError(error)))
            case .success(let token):

                let formatter = ISO8601DateFormatter()
                let parameters = [
                    "index": "\(index)",
                    "length": "\(length)",
                    "startDate": formatter.string(from: startDate),
                    "endDate": formatter.string(from: endDate)
                    ] as [String : Any]

                let urlString = "\(Constants.baseUrl)/Bank/api/v2/Transactions/\(userId)/\(accountNumber)"
                guard let request = self.urlRequest(urlString, token: token, parameters: parameters) else { return }

                self.urlSession.dataTask(with: request, completionHandler: { data, response, error in

                    guard error == nil else {
                        completion(.failure(SbankenError(error)))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.missingNetworkResponse))
                        return
                    }

                    if let transactionResponse = try? self.decoder.decode(TransactionResponse.self, from: data) {
                        completion(.success(transactionResponse))
                    } else {
                        completion(.failure(.unableToDecodeNetworkResponse))
                    }
                }).resume()
            }
        }
    }

    public func transfer(userId: String,
                         fromAccount: String,
                         toAccount: String,
                         message: String,
                         amount: Float,
                         completion: @escaping (Result<TransferResponse, SbankenError>) -> Void) {

        accessToken(clientId: clientId, secret: secret) { result in

            switch result {
            case .failure(let error):
                completion(.failure(SbankenError(error)))
            case .success(let token):

                let urlString = "\(Constants.baseUrl)/Bank/api/v1/Transfers/\(userId)"
                guard var request = self.urlRequest(urlString, token: token) else { return }

                let transferRequest = TransferRequest(fromAccount: fromAccount, toAccount: toAccount, message: message, amount: amount)

                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                if let body = try? self.encoder.encode(transferRequest) {
                    request.httpBody = body
                } else {
                    completion(.failure(.unableToDecodeNetworkResponse))
                }

                self.urlSession.dataTask(with: request, completionHandler: { (data, response, error) in

                    guard error == nil else {
                        completion(.failure(SbankenError(error)))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.missingNetworkResponse))
                        return
                    }

                    if let transferResponse = try? self.decoder.decode(TransferResponse.self, from: data) {
                        if transferResponse.isError {
                            completion(.failure(SbankenError(transferResponse.errorMessage ?? "Undefined error")))
                        } else {
                            completion(.success(transferResponse))
                        }
                    } else {
                        completion(.failure(.unableToDecodeNetworkResponse))
                    }
                }).resume()
            }
        }
    }

    private func urlRequest(_ urlString: String, token: AccessToken, parameters: [String: Any]) -> URLRequest? {
        guard var request = urlRequest(urlString, token: token) else { return nil }
        guard let originalUrl = request.url?.absoluteString else { return nil }
        request.url = URL(string: "\(originalUrl)?\(parameters.stringFromHttpParameters())")
        return request
    }

    private func urlRequest(_ urlString: String, token: AccessToken) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func accessToken(clientId: String, secret: String, completion: @escaping (Result<AccessToken, SbankenError>) -> Void) {

        if let token = tokenManager.token {
            completion(.success(token))
            return
        }

        let credentialData = "\(clientId):\(secret)".data(using: .utf8)!
        let encodedCredentials = credentialData.base64EncodedString()

        let url = URL(string: "\(Constants.baseUrl)/identityserver/connect/token")
        var request = URLRequest(url: url!)

        [
            "Authorization": "Basic \(encodedCredentials)",
            "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
            "Accept": "application/json"
            ].forEach { key, value in request.setValue(value, forHTTPHeaderField: key) }

        request.httpMethod = "POST"
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        self.urlSession.dataTask(with: request, completionHandler: { (data, response, error) in

            if let error = error {
                completion(.failure(SbankenError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.missingNetworkResponse))
                return
            }

            if let token = try? self.decoder.decode(AccessToken.self, from: data) {
                self.tokenManager.token = token
                completion(.success(token))
            } else {
                completion(.failure(.unableToDecodeNetworkResponse))
            }
        }).resume()
    }
}

