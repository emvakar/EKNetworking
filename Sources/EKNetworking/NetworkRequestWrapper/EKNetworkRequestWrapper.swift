//
//  EKNetworkTokenRefresher.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import Logging
import PulseLogHandler
import Pulse

public protocol EKNetworkRequestWrapperProtocol {

    func runRequest(request: EKNetworkRequest,
                    baseURL: String,
                    authToken: (() -> String?)?,
                    progressResult: ((Double) -> Void)?,
                    showBodyResponse: Bool,
                    timeoutInSeconds: TimeInterval,
                    completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void)

}

public protocol EKErrorHandleDelegate: AnyObject {

    func handle(error: EKNetworkError?, statusCode: Int)

}

open class EKNetworkRequestWrapper: EKNetworkRequestWrapperProtocol {

    /// Error handler Delegate
    public weak var delegate: EKErrorHandleDelegate?
    public var logEnable: Bool

    public init(logging: Logger? = nil, logEnable: Bool = false) {
        if let logging = logging {
            logger = logging
        }
        self.logEnable = logEnable
    }

    open func runRequest(request: EKNetworkRequest,
                         baseURL: String,
                         authToken: (() -> String?)?,
                         progressResult: ((Double) -> Void)?,
                         showBodyResponse: Bool = false,
                         timeoutInSeconds: TimeInterval,
                         completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        let target = EKNetworkTarget(request: request, tokenFunction: authToken, baseURL: baseURL)

        logger.debug("[NETWORK]: Start request to \(baseURL)\(request.path)")
        self.runWith(target: target, progressResult: progressResult, timeoutInSeconds: timeoutInSeconds, completion: { (statusCode, response, error) in
            if showBodyResponse {
                #if DEBUG
                let body: String = response.map { String(data: $0.data, encoding: .utf8) ?? "" } ?? ""
                logger.debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                logger.debug("[NETWORK]: Response status code: \(statusCode)")
                logger.debug("[NETWORK]: Response url: \(baseURL + target.path)")
                logger.debug("[NETWORK]: Response headers: \(target.headers ?? [:])")
                logger.debug("[NETWORK]: Response body: \(String(describing: body))")
                if let code = error?.errorCode, let plainBody = error?.plainBody {
                    logger.debug("[NETWORK]: Response error code \(String(describing: code)) body: \(String(describing: plainBody))")
                }
                logger.debug("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                #endif
            }
            self.delegate?.handle(error: error, statusCode: statusCode)
            completion(statusCode, response, error)
        })
    }

    private func runWith(target: EKNetworkTarget,
                         progressResult: ((Double) -> Void)?,
                         timeoutInSeconds: TimeInterval,
                         completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        let requestStartTime = DispatchTime.now()

        class DefaultAlamofireSession: Alamofire.Session {

            static func shared(timeoutInSeconds: TimeInterval = 30, logEnable: Bool = false) -> DefaultAlamofireSession {
                let configuration = URLSessionConfiguration.default
                var eventMonitors: [EventMonitor] = []
                if logEnable {
                    let log: NetworkLogger = NetworkLogger()
                    eventMonitors = [EKNetworkLoggerMonitor(logger: log)]
                }
                configuration.headers = .default
                configuration.timeoutIntervalForRequest = timeoutInSeconds // as seconds, you can set your request timeout
                configuration.timeoutIntervalForResource = timeoutInSeconds // as seconds, you can set your resource timeout
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return DefaultAlamofireSession(configuration: configuration, eventMonitors: eventMonitors)
            }
        }

        let provider = MoyaProvider<EKNetworkTarget>(session: DefaultAlamofireSession.shared(timeoutInSeconds: timeoutInSeconds, logEnable: logEnable))
        provider.request(target, progress: { (progressResponse) in

            let progress = progressResponse.progress
            progressResult?(progress)

        }) { (resultResponse) in

            let requestEndTime = DispatchTime.now()
            let requestTime = requestEndTime.uptimeNanoseconds - requestStartTime.uptimeNanoseconds
            logger.debug("[NETWORK]: Duration is \((Double(requestTime) / 1_000_000_000).roundWithPlaces(2)) sec")

            switch resultResponse {

            case .success(let response):

                if 200...299 ~= response.statusCode {
                    completion(response.statusCode, response, nil)
                } else {
                    let networkError = EKNetworkErrorStruct(statusCode: response.statusCode, data: response.data)
                    completion(response.statusCode, nil, networkError)
                }

                // если отправка не прошла на нашей стороне
            case .failure(let error):
                switch error {
                case .underlying(let nsError as NSError, let response):
                    let networkError = EKNetworkErrorStruct(statusCode: nsError.code, data: response?.data)
                    completion(nsError.code, nil, networkError)
                default:
                    break
                }
            }
        }
    }
}
