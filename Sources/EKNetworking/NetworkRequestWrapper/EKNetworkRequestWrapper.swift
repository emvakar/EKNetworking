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
import LoggingTelegram

public protocol EKNetworkRequestWrapperProtocol {

    func runRequest(request: EKNetworkRequest,
                    baseURL: String,
                    authToken: (() -> String?)?,
                    progressResult: ((Double) -> Void)?,
                    showBodyResponse: Bool,
                    completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void)

}

public protocol EKErrorHandleDelegate: AnyObject {

    func handle(error: EKNetworkError?, statusCode: Int)

}

open class EKNetworkRequestWrapper: EKNetworkRequestWrapperProtocol {

    /// Error handler Delegate
    public weak var delegate: EKErrorHandleDelegate?

    public init(logging: Logger? = nil) {
        if let logging = logging {
            logger = logging
        }
    }

    open func runRequest(request: EKNetworkRequest,
                         baseURL: String,
                         authToken: (() -> String?)?,
                         progressResult: ((Double) -> Void)?,
                         showBodyResponse: Bool = false,
                         completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        let target = EKNetworkTarget(request: request, tokenFunction: authToken, baseURL: baseURL)

        self.runWith(target: target, progressResult: progressResult, completion: { (statusCode, response, error) in
            if showBodyResponse {
                #if DEBUG
                let body: String = response.map { String(data: $0.data, encoding: .utf8) ?? "" } ?? ""
                logger.debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                logger.debug("Request status code: \(statusCode)")
                logger.debug("Request url: \(baseURL + target.path)")
                logger.debug("Request headers: \(target.headers ?? [:])")
                logger.debug("Request body: \(String(describing: body))")
                if let code = error?.errorCode, let plainBody = error?.plainBody {
                    logger.debug("Request error code \(String(describing: code)) body: \(String(describing: plainBody))")
                }
                logger.debug("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                #endif
            }
            self.delegate?.handle(error: error, statusCode: statusCode)
            completion(statusCode, response, error)
        })
    }

    private func runWith(target: EKNetworkTarget, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        let requestStartTime = DispatchTime.now()

        class DefaultAlamofireSession: Alamofire.Session {

            static let shared: DefaultAlamofireSession = {
                let configuration = URLSessionConfiguration.default
                configuration.headers = .default
                configuration.timeoutIntervalForRequest = 30 // as seconds, you can set your request timeout
                configuration.timeoutIntervalForResource = 30 // as seconds, you can set your resource timeout
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return DefaultAlamofireSession(configuration: configuration)
            }()
        }

        let provider = MoyaProvider<EKNetworkTarget>(session: DefaultAlamofireSession.shared)
        provider.request(target, progress: { (progressResponse) in

            let progress = progressResponse.progress
            progressResult?(progress)

        }) { (resultResponse) in

            let requestEndTime = DispatchTime.now()
            let requestTime = requestEndTime.uptimeNanoseconds - requestStartTime.uptimeNanoseconds
            logger.debug("Продолжительность запроса: \((Double(requestTime) / 1_000_000_000).roundWithPlaces(2)) секунд")

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
