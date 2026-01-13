//
//  NetworkLogger+Extensions.swift
//  EKNetworking
//
//  Created by Egor Solovev on 13.01.2026.
//  Copyright © 2026 TAXCOM. All rights reserved.
//

import Foundation
import PulseLogHandler

extension NetworkLogger {
    
    /// Logs when a URLSessionTask is created from a URLRequest
    func logTaskCreated(_ request: URLRequest) {
        // Create a minimal data task just for logging initialization
        // This matches Pulse's expected logging flow
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: request)
        logTaskCreated(task)
    }
    
    /// Logs response data from a URLRequest and HTTPURLResponse
    func logDataTask(_ request: URLRequest, response: HTTPURLResponse, data: Data) {
        // Create a minimal data task just for logging the response
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: request)
        logDataTask(task, didReceive: data)
    }
}
