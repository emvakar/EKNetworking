//
//  EKNetworkRequest.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import Moya

public enum EKRequestHTTPMethod: String {

    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public protocol EKNetworkRequest {
    var path: String { get }
    var method: EKRequestHTTPMethod { get }
    var urlParameters: [String: Any] { get }
    var bodyParameters: [String: Any] { get }
    var multipartBody: [MultipartFormData]? { get }
    var headers: [EKHeadersKey: String] { get }

}
public extension EKNetworkRequest {

    var multipartBody: [MultipartFormData]? {
        return nil
    }
}
