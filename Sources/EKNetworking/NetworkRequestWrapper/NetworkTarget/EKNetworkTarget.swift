//
//  EKNetworkTarget.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

/// Common HTTP header keys used in network requests
public enum EKHeadersKey: String {

    case content_type = "Content-Type"
    case accept_language = "Accept-Language"
    case os = "os"
    case os_version = "os_version"
    case head = "head"
    case date = "date"
    case authorization = "Authorization"
    case sessionToken = "Session-Token"
    case app_version = "app_version"
    case app_build = "app_build"
    case app_identifier = "app_identifier"
    case device_model = "device_model"
    case device_uuid = "device_uuid"
    case api = "api"
    case fcm = "fcm"

}

/// Internal target helper (kept for backward compatibility, but no longer uses Moya)
/// This struct is now primarily used as a data holder during request construction
struct EKNetworkTarget {

    let apiRequest: EKNetworkRequest
    let tokenFunction: (() -> String?)?
    let baseURL: URL

    init(request: EKNetworkRequest, tokenFunction: (() -> String?)?, baseURL: String) {
        apiRequest = request
        self.tokenFunction = tokenFunction
        self.baseURL = URL(string: baseURL)! // swiftlint:disable:this force_unwrapping
    }

    /// URL path
    var path: String {
        return apiRequest.path
    }

    /// Headers including authorization
    var headers: [String: String]? {
        var dictionary = [String: String]()
        if let value = apiRequest.headers {
            value.forEach { dictionary.updateValue($0.value, forKey: $0.key) }
        }

        guard let authFunc = tokenFunction, let value = authFunc() else { return dictionary }
        
        switch apiRequest.authHeader {
        case .bearerToken:
            let token = "Bearer " + value
            dictionary.updateValue(token, forKey: EKHeadersKey.authorization.rawValue)
        case .sessionToken:
            dictionary.updateValue(value, forKey: EKHeadersKey.sessionToken.rawValue)
        }
        
        return dictionary
    }
}
