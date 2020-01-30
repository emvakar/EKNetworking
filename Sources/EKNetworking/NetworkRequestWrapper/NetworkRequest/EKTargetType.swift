//
//  EKTargetType.swift
//  EKNetworking
//
//  Created by Emil Karimov on 26.10.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public protocol EKTargetType {

    /// The target's base `URL`.
    var baseURL: URL { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: EKRequestHTTPMethod { get }

    /// Provides stub data for use in testing.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: Task { get }

    /// The type of validation to perform on the request. Default is `.none`.
    var validationType: ValidationType { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}

public extension EKTargetType {

    /// The type of validation to perform on the request. Default is `.none`.
    var validationType: EKValidationType {
        return .none
    }
}
