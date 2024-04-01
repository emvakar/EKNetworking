//
//  EKNetworkLoggerMonitor.swift
//  EKNetworking
//
//  Created by Emil Karimov on 21.02.2024.
//  Copyright © 2024 Emil Karimov. All rights reserved.
//

import OSLog
import Alamofire
import PulseLogHandler

struct EKNetworkLoggerMonitor: EventMonitor {

    let log: NetworkLogger

    init(logger: NetworkLogger) {
        self.log = logger
    }

    func request(_ request: Request, didCreateTask task: URLSessionTask) {
        log.logTaskCreated(task)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        log.logDataTask(dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        log.logTask(task, didFinishCollecting: metrics)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        log.logTask(task, didCompleteWithError: error)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) {
        log.logDataTask(dataTask, didReceive: proposedResponse.data)
    }
}
