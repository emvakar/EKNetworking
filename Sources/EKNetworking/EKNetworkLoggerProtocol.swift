//
//  EKNetworkLoggerProtocol.swift
//  EKNetworking
//
//  Created by Egor Solovev on 20.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

/// Protocol for network logging abstraction
/// This allows for dependency injection and easy removal/replacement of logging implementations
public protocol EKNetworkLoggerProtocol {
    
    /// Logs when a URLSessionTask is created
    /// - Parameter task: The created task
    func logTaskCreated(_ task: URLSessionTask)
    
    /// Logs when a data task receives data
    /// - Parameters:
    ///   - task: The data task that received data
    ///   - data: The received data
    func logDataTask(_ task: URLSessionDataTask, didReceive data: Data)
    
    /// Logs when a task completes (with or without error)
    /// - Parameters:
    ///   - task: The completed task
    ///   - error: Optional error if task failed
    func logTask(_ task: URLSessionTask, didCompleteWithError error: Error?)
}
