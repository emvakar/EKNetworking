//
//  EKNetworkRequestWrapperProtocol+Async.swift
//  EKNetworking
//
//  Created by Egor Solovev on 16.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

// MARK: - Swift Concurrency Support

/// Default implementation of async method for all protocol conformers
@available(iOS 13.0, macOS 10.15, *)
public extension EKNetworkRequestWrapperProtocol {
    
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
        authToken: (() -> String?)? = nil,
        progressResult: ((Double) -> Void)? = nil,
        showBodyResponse: Bool = false,
        timeoutInSeconds: TimeInterval
    ) async throws -> EKResponse {
        
        try await withCheckedThrowingContinuation { continuation in
            // Call the completion handler version
            runRequest(
                request: request,
                baseURL: baseURL,
                authToken: authToken,
                progressResult: progressResult,
                showBodyResponse: showBodyResponse,
                timeoutInSeconds: timeoutInSeconds
            ) { statusCode, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response {
                    continuation.resume(returning: response)
                } else {
                    // Fallback error - should never happen in practice
                    let fallbackError = EKNetworkErrorStruct(
                        statusCode: statusCode,
                        data: nil
                    )
                    continuation.resume(throwing: fallbackError)
                }
            }
        }
    }
}
