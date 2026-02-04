//
//  EKNetworkTokenRefresher.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public protocol EKNetworkTokenRefresherProtocol {

    // Обновление токена при 401 ошибке
    func refreshAuthToken(completion: @escaping (EKNetworkError?) -> Void)

    // Обновление токена при 5012 ошибке для ДСС токена
    func refreshDSSAuthToken(completion: @escaping (EKNetworkError?) -> Void)

}

public extension EKNetworkTokenRefresherProtocol {

    // Дефолтная реализация обновление токена ДСС
    func refreshDSSAuthToken(completion: @escaping (EKNetworkError?) -> Void) {
        completion(nil)
    }

}

// MARK: - Bridge to Async Protocol

/// Bridge implementation that provides async protocol conformance for any type
/// that conforms to EKNetworkTokenRefresherProtocol
@available(iOS 13.0, macOS 10.15, *)
public extension EKNetworkTokenRefresherAsyncProtocol where Self: EKNetworkTokenRefresherProtocol {
    
    /// Default async implementation that wraps completion-based version
    func refreshAuthToken() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            refreshAuthToken { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    /// Default async implementation for DSS that wraps completion-based version
    func refreshDSSAuthToken() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            refreshDSSAuthToken { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
