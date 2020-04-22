//
//  EKNetworkRequest.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import Moya

public enum EKRequestHTTPMethod {
    case get
    case post
    case put
    case patch
    case delete
    case multiple
}

public protocol EKNetworkRequest {
    var path: String { get }
    var method: EKRequestHTTPMethod { get }
    var urlParameters: [String: Any]? { get }
    var bodyParameters: [String: Any]? { get }
    var multipartBody: [MultipartFormData]? { get }
    var headers: [EKHeadersKey: String]? { get }

}

public extension EKNetworkRequest {
    var urlParameters: [String: Any]? { return nil }
    var bodyParameters: [String: Any]? { return nil }
    var multipartBody: [MultipartFormData]? { return nil }
    var headers: [EKHeadersKey: String]? { return nil }
}
