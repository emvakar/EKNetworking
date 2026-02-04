//
//  EKNetworkTokenRefresherAsyncProtocol.swift
//  EKNetworking
//
//  Created by Egor Solovev on 03.02.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

/// Async/await protocol for token refresh operations using Swift concurrency
@available(iOS 13.0, macOS 10.15, *)
public protocol EKNetworkTokenRefresherAsyncProtocol {
    
    /// Async version of refreshAuthToken
    ///
    /// Refreshes the authentication token when a 401 error occurs.
    ///
    /// - Throws: EKNetworkError if token refresh fails
    func refreshAuthToken() async throws
    
    /// Async version of refreshDSSAuthToken
    ///
    /// Refreshes the DSS authentication token when a 5012 error occurs.
    ///
    /// - Throws: EKNetworkError if DSS token refresh fails
    func refreshDSSAuthToken() async throws
}

/// Default implementation for DSS token refresh
@available(iOS 13.0, macOS 10.15, *)
public extension EKNetworkTokenRefresherAsyncProtocol {
    
    /// Default implementation that does nothing
    /// Override this if you need DSS token refresh functionality
    func refreshDSSAuthToken() async throws {
        // Default: no-op
    }
}
