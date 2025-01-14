//
//  EKNetworkLoggerMonitor.swift
//  EKNetworking
//
//  Created by Emil Karimov on 21.02.2024.
//  Copyright © 2024 Emil Karimov. All rights reserved.
//

import Foundation
import Alamofire
import PulseLogHandler

/// A network logger monitor for Alamofire requests, integrated with Pulse.
struct EKNetworkLoggerMonitor: EventMonitor {
    
    // MARK: - Properties
    
    let log: NetworkLogger
    
    // MARK: - Initializer
    
    init(logger: NetworkLogger) {
        self.log = logger
    }
    
    // MARK: - EventMonitor Methods
    
    func request(_ request: Request, didCreateTask task: URLSessionTask) {
        log.logTaskCreated(task)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logDataTask(dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        log.logTask(task, didFinishCollecting: metrics)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        log.logTask(task, didCompleteWithError: error)
    }
    
    // MARK: - Private Helpers
    
    private func logDataTask(_ dataTask: URLSessionDataTask, didReceive data: Data) {
        if let prettyString = serialize(data: data) {
            logResponse(dataTask: dataTask, responseBody: prettyString)
        } else {
            logResponse(dataTask: dataTask, responseBody: "Unable to serialize response body")
        }
    }
    
    private func logResponse(dataTask: URLSessionDataTask, responseBody: String) {
        guard let originalRequest = dataTask.originalRequest else { return }
        log.logDataTask(dataTask, didReceive: Data(responseBody.utf8))
    }
    
    private func serialize(data: Data) -> String? {
        // Попытка сериализовать JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        // Если не JSON, пытаемся преобразовать в текст
        return String(data: data, encoding: .utf8)
    }
}
