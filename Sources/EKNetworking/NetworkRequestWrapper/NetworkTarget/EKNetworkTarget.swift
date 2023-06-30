//
//  EKNetworkTarget.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Moya
import Foundation

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

struct EKNetworkTarget: TargetType {

    let apiRequest: EKNetworkRequest
    let tokenFunction: (() -> String?)?

    init(request: EKNetworkRequest, tokenFunction: (() -> String?)?, baseURL: String) {
        apiRequest = request
        self.tokenFunction = tokenFunction
        self.baseURL = URL(string: baseURL)! // swiftlint:disable:this force_unwrapping
    }

    var baseURL: URL

    /// URL path
    var path: String {
        return apiRequest.path
    }

    ///  Method
    var method: Moya.Method {
        switch apiRequest.method {
        case .get:       return .get
        case .post:      return .post
        case .multiple:  return .post
        case .put:       return .put
        case .delete:    return .delete
        case .patch:     return .patch
        case .options:   return .options
        case .head:      return .head
        case .trace:     return .trace
        case .connect:   return .connect
        }
    }

    /// для мок реализации запроса в юнит тестах (если потребуется, то поменять)
    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch apiRequest.method {
        case .get:
            guard let urlParameters = apiRequest.urlParameters else {
                return .requestPlain
            }
            return urlParameters.isEmpty ? .requestPlain : .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
        case .post, .multiple, .put, .delete, .patch, .options, .head, .trace, .connect:
            if let multipart = apiRequest.multipartBody {
                return .uploadCompositeMultipart(multipart,
                                                 urlParameters: apiRequest.urlParameters ?? [:])
            }
            if let jsonArray = apiRequest.array,
               let arrayData = try? JSONSerialization.data(withJSONObject: jsonArray) {
                return .requestCompositeData(bodyData: arrayData, urlParameters: apiRequest.urlParameters ?? [:])
            }
            return .requestCompositeParameters(bodyParameters: (apiRequest.bodyParameters ?? [:]),
                                               bodyEncoding: JSONEncoding.default,
                                               urlParameters: apiRequest.urlParameters ?? [:])
        }
    }

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
