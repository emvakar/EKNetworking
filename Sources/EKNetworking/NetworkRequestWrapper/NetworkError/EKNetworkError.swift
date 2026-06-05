//
//  EKNetworkError.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import os.log

// MARK: - EKNetworkErrorType

public enum EKNetworkErrorType: Equatable {

    case noConnection
    case lostConnection
    case unauthorized
    case internalServerError
    case badRequest
    case cancelled
    case timedOut
    case notFound
    case forbidden
    case unspecified(statusCode: Int)

}

// MARK: - EKNetworkError

public protocol EKNetworkError: Error {

    var statusCode: Int { get }
    var type: EKNetworkErrorType { get }
    var errorCode: Int? { get }
    var description: String? { get }
    var message: String? { get }
    var plainBody: String? { get }
    var detailMessage: String? { get }
    var data: Data? { get set }

}

// MARK: - EKNetworkErrorStruct

open class EKNetworkErrorStruct: EKNetworkError {

    public var statusCode: Int = 0
    public var type: EKNetworkErrorType = .unspecified(statusCode: 0)
    public var errorCode: Int?
    public var description: String?
    public var message: String?
    public var plainBody: String?
    public var detailMessage: String?
    public var userInfo: [String: Any]? // полезно при ошибке JSONDecoder (если неверны ключи), вытащить можно только из NSError
    public var data: Data?

    // MARK: - Public

    /// Creates an error from an HTTP status code and optional response body.
    /// - Parameters:
    ///   - statusCode: HTTP status code or `URLError` code. Pass `nil` to get a default empty instance.
    ///   - data: Raw response body, if any.
    public init(statusCode: Int?, data: Data?) {
        guard let statusCode = statusCode else {
            return
        }

        self.statusCode = statusCode
        self.setNetworkErrorType(from: statusCode)
        self.parseData(data: data, statusCode: statusCode)
        self.data = data
    }

    /// Creates an error from an underlying `NSError` (e.g. `JSONDecoder` failure).
    /// - Parameter error: The underlying system error.
    public init(error: NSError) {
        self.statusCode = error.code
        self.setNetworkErrorType(from: error.code)
        self.description = error.localizedDescription
        self.message = error.localizedDescription
        self.detailMessage = error.localizedDescription
        self.userInfo = error.userInfo
    }

    /// Parses the response body and fills message fields from JSON when possible.
    /// Override in a subclass to support a custom error payload format.
    /// - Parameters:
    ///   - data: Raw response body.
    ///   - statusCode: HTTP or `URLError` status code.
    open func parseData(data: Data?, statusCode: Int?) {
        guard let data = data else {
            return
        }

        self.plainBody = String(data: data, encoding: .utf8)

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            self.errorCode = statusCode
            self.description = json?["reason"] as? String
            self.message = json?["reason"] as? String
            self.detailMessage = json?["reason"] as? String
            self.userInfo = json
        } catch let error {
            os_log(.error, log: OSLog(subsystem: "com.eknetworking.network", category: "error"),
                   "Can't parse network error body: %{public}@", error.localizedDescription)
        }
    }
}

// MARK: - Private

private extension EKNetworkErrorStruct {

    func setNetworkErrorType(from statusCode: Int) {
        let networkErrorType: EKNetworkErrorType

        switch statusCode {
        case URLError.notConnectedToInternet.rawValue, URLError.cannotFindHost.rawValue, URLError.cannotConnectToHost.rawValue:
            networkErrorType = .noConnection
        case URLError.timedOut.rawValue:
            networkErrorType = .timedOut
        case URLError.networkConnectionLost.rawValue:
            networkErrorType = .lostConnection
        case 400:
            networkErrorType = .badRequest
        case 401:
            networkErrorType = .unauthorized
        case 404:
            networkErrorType = .notFound
        case 403:
            networkErrorType = .forbidden
        case 500...599:
            networkErrorType = .internalServerError
        default:
            networkErrorType = .unspecified(statusCode: statusCode)
        }

        self.type = networkErrorType
    }
}
