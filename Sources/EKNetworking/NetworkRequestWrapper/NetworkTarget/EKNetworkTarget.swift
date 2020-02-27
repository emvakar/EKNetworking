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
    case osVersion = "os_version"
    case device = "model"
    case head = "head"
    case date = "date"
    case authorization = "Authorization"
    case deviceUUID = "device"
    case app_version = "app_version"
    case app_build = "app_build"
    case api = "api"
    case fcm = "fcm"
}

public struct EKNetworkTarget: TargetType {

    let apiRequest: EKNetworkRequest
    let authToken: String?

    public init(request: EKNetworkRequest, token: String?, baseURL: String) {
        self.apiRequest = request
        self.authToken = token
        self.baseURL = URL(string: baseURL)!
    }

    public var baseURL: URL

    public var path: String {
        return apiRequest.path
    }

    public var method: Moya.Method {
        switch apiRequest.method {
        case .get:
            return .get
        case .post, .multiple:
            return .post
        case .put:
            return .put
        case .delete:
            return .delete
        case .patch:
            return .patch
        }
    }

    //для мок реализации запроса в юнит тестах (если потребуется, то поменять)
    public var sampleData: Data {
        return Data()
    }

    public var task: Task {
        switch apiRequest.method {
        case .get:
            return apiRequest.urlParameters.count == 0 ? .requestPlain : .requestParameters(parameters: apiRequest.urlParameters, encoding: URLEncoding.default)
        case .post, .multiple, .put, .delete, .patch:
            if let multipart = apiRequest.multipartBody {
                return .uploadCompositeMultipart(multipart, urlParameters: apiRequest.urlParameters)
            }
            return .requestCompositeParameters(bodyParameters: apiRequest.bodyParameters, bodyEncoding: JSONEncoding.default, urlParameters: apiRequest.urlParameters)
        }
    }

    public var headers: [String: String]? {
        
        var dictionary = [String: String]()
        self.apiRequest.headers.forEach {
            dictionary.updateValue($0.value, forKey: $0.key.rawValue)
        }
        
        if let value = authToken {
            dictionary.updateValue(value, forKey: EKHeadersKey.authorization.rawValue)
        }
        return dictionary
    }
}
