//
//  EKNetworkTokenRefresher.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import Moya

public protocol EKNetworkRequestWrapperProtocol {

    func runRequest(request: EKNetworkRequest, baseURL: String, authToken: (() -> String?)?, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ requestData: Data?, _ error: EKNetworkError?) -> Void)

}

public protocol EKErrorHandleDelegate: AnyObject {

    func handle(error: EKNetworkError?, statusCode: Int)

}

open class EKNetworkRequestWrapper: EKNetworkRequestWrapperProtocol {

    /// Error handler Delegate
    public weak var delegate: EKErrorHandleDelegate?

    public init() { }

    open func runRequest(request: EKNetworkRequest, baseURL: String, authToken: (() -> String?)?, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ requestData: Data?, _ error: EKNetworkError?) -> Void) {

        let target = EKNetworkTarget(request: request, tokenFunction: authToken, baseURL: baseURL)

        self.runWith(target: target, progressResult: progressResult, completion: { (statusCode, data, error) in
            #if DEBUG
            let body: String? = data != nil ? String(data: data!, encoding: .utf8) : "" // swiftlint:disable:this force_unwrapping
            ekNetworkLog(Self.self, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            ekNetworkLog(Self.self, "Request status code: \(statusCode)")
            ekNetworkLog(Self.self, "Request url: \(baseURL + target.path)")
            ekNetworkLog(Self.self, "Request headers: \(target.headers ?? [:])")
            ekNetworkLog(Self.self, "Request body: \(String(describing: body))")
            if let code = error?.errorCode, let plainBody = error?.plainBody {

                ekNetworkLog(Self.self, "Request error code \(String(describing: code)) body: \(String(describing: plainBody))")
            }
            ekNetworkLog(Self.self, "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
            #endif
            self.delegate?.handle(error: error, statusCode: statusCode)
            completion(statusCode, data, error)
        })
    }

    private func runWith(target: EKNetworkTarget, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ responseData: Data?, _ error: EKNetworkError?) -> Void) {

        let requestStartTime = DispatchTime.now()

        let provider = MoyaProvider<EKNetworkTarget>()
        provider.request(target, progress: { (progressResponse) in

            let progress = progressResponse.progress
            progressResult?(progress)

        }) { (resultResponse) in

            let requestEndTime = DispatchTime.now()
            let requestTime = requestEndTime.uptimeNanoseconds - requestStartTime.uptimeNanoseconds
            ekNetworkLog(Self.self, "Продолжительность запроса: \((Double(requestTime) / 1_000_000_000).roundWithPlaces(2)) секунд")

            switch resultResponse {

            case .success(let response):

                if 200...299 ~= response.statusCode {
                    completion(response.statusCode, response.data, nil)
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
