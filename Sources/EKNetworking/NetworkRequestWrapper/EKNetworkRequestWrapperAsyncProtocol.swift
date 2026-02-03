//
//  EKNetworkRequestWrapperAsyncProtocol.swift
//  EKNetworking
//
//  Created by Egor Solovev on 03.02.2026.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

/// Async/await protocol for network request execution using Swift concurrency
@available(iOS 13.0, macOS 10.15, *)
public protocol EKNetworkRequestWrapperAsyncProtocol {
    
    /// Async version of runRequest using modern Swift concurrency
    ///
    /// Provides a throwing async interface for making network requests.
    /// Throws `EKNetworkError` on failure, returns `EKResponse` on success.
    ///
    /// - Parameters:
    ///   - request: The network request conforming to EKNetworkRequest
    ///   - baseURL: Base URL string for the request
    ///   - authToken: Optional closure returning authentication token
    ///   - progressResult: Optional closure for tracking upload/download progress
    ///   - showBodyResponse: Whether to log request/response details
    ///   - timeoutInSeconds: Request timeout in seconds
    ///
    /// - Returns: EKResponse on success
    /// - Throws: EKNetworkError on failure (network error, timeout, non-2xx status code)
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let response = try await wrapper.runRequest(
    ///         request: myRequest,
    ///         baseURL: "https://api.example.com",
    ///         authToken: { "token" },
    ///         timeoutInSeconds: 30
    ///     )
    ///     print("Success: \(response.statusCode)")
    /// } catch let error as EKNetworkError {
    ///     print("Error: \(error.type)")
    /// }
    /// ```
    func runRequest(
        request: EKNetworkRequest,
        baseURL: String,
        authToken: (() -> String?)?,
        progressResult: ((Double) -> Void)?,
        showBodyResponse: Bool,
        timeoutInSeconds: TimeInterval
    ) async throws -> EKResponse
}
