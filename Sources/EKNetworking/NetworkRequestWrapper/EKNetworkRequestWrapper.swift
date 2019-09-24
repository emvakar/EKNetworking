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
    func runRequest(_ request: EKNetworkRequest, baseURL: String, authToken: String?, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ requestData: Data?, _ error: EKNetworkError?) -> Void)
}

public protocol EKErrorHandleDelegate: class {
    func handle(error: EKNetworkError?, statusCode: Int)
}

public class EKNetworkRequestWrapper: EKNetworkRequestWrapperProtocol {
    
    weak var delegate: EKErrorHandleDelegate?
    
    public func runRequest(_ request: EKNetworkRequest, baseURL: String, authToken: String?, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ requestData: Data?, _ error: EKNetworkError?) -> Void) {

        let target = EKNetworkTarget(request: request, token: authToken, baseURL: baseURL)

        self.runWith(target: target, progressResult: progressResult, completion: { (statusCode, data, error) in
            #if DEBUG
                let body: String? = data != nil ? String.init(data: data!, encoding: .utf8) : ""
                print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                print("Request status code: \(statusCode)")
                print("Request url: \(baseURL + target.path)")
                print("Request headers: \(target.headers ?? [:])")
                print("Request body: \(String(describing: body))")
                print("Request error code \(String(describing: error?.errorCode)) body: \(String(describing: error?.plainBody))")
                print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
            #endif
            self.delegate?.handle(error: error, statusCode: statusCode)
//            if statusCode == 500 && (error?.detailMessage ?? "").contains("TestFlight") {
//                NotificationCenter.default.post(name: .updateNeeded, object: error?.detailMessage, userInfo: nil)
//            }
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
            print("Продолжительность запроса: \((Double(requestTime) / 1_000_000_000).roundWithPlaces(6)) секунд")

            switch resultResponse {

            case .success(let response):

                if 200...299 ~= response.statusCode {
                    completion(response.statusCode, response.data, nil)
                } else {
                    let networkError = EKNetworkErrorStruct(statusCode: response.statusCode, data: response.data)
                    completion(response.statusCode, nil, networkError)
                }

                //если отправка не прошла на нашей стороне
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
