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
    
    // Async versions
    @available(iOS 13.0, macOS 10.15, *)
    func refreshAuthToken() async throws
    
    @available(iOS 13.0, macOS 10.15, *)
    func refreshDSSAuthToken() async throws

}

public extension EKNetworkTokenRefresherProtocol {

    // Дефолтная реализация обновление токена ДСС
    func refreshDSSAuthToken(completion: @escaping (EKNetworkError?) -> Void) {
        completion(nil)
    }
    
    // Default async implementation that wraps completion-based version
    @available(iOS 13.0, macOS 10.15, *)
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
    
    // Default async implementation for DSS
    @available(iOS 13.0, macOS 10.15, *)
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
