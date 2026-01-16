//
//  EKResponse.swift
//  EKNetworking
//
//  Created by Egor Solovev on 13.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

/// Response type that replaces Moya's Response with native implementation
public final class EKResponse {
    
    /// The HTTP status code of the response.
    public let statusCode: Int
    
    /// The raw data returned by the server.
    public let data: Data
    
    /// The original URLRequest sent to the server.
    public let request: URLRequest?
    
    /// The HTTPURLResponse from the server.
    public let response: HTTPURLResponse?
    
    /// Initializes a response object.
    /// - Parameters:
    ///   - statusCode: The HTTP status code.
    ///   - data: The response data.
    ///   - request: The original request.
    ///   - response: The HTTP response object.
    public init(statusCode: Int, data: Data, request: URLRequest?, response: HTTPURLResponse?) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }
    
    /// Convenience initializer from URLSession response
    /// - Parameters:
    ///   - data: The response data.
    ///   - response: The URL response.
    ///   - request: The original request.
    public convenience init(data: Data, response: URLResponse, request: URLRequest?) {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        self.init(statusCode: statusCode, data: data, request: request, response: httpResponse)
    }
}
