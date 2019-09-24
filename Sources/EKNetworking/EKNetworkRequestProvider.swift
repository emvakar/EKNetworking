//
//  EKNetworkRequestProvider.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public class EKNetworkRequestProvider {

    let networkWrapper: EKNetworkRequestWrapperProtocol
    let tokenRefresher: EKNetworkTokenRefresherProtocol?
    let accountManager: EKAccountManagerProtocol

    public init(networkWrapper: EKNetworkRequestWrapperProtocol, tokenRefresher: EKNetworkTokenRefresherProtocol?, accountManager: EKAccountManagerProtocol) {
        self.networkWrapper = networkWrapper
        self.tokenRefresher = tokenRefresher
        self.accountManager = accountManager
    }

    public func runRequest(_ request: EKNetworkRequest, progressResult: ((Double) -> Void)?, completion: @escaping(_ statusCode: Int, _ requestData: Data?, _ error: EKNetworkError?) -> Void) {

        let baseUrl = self.accountManager.getBaseUrl()
        var tokenString: String?
        let token = accountManager.getUserToken()
        if !token.isEmpty {
            tokenString = "Bearer " + accountManager.getUserToken()
        }

        let s = self
        self.networkWrapper.runRequest(request, baseURL: baseUrl, authToken: tokenString, progressResult: progressResult) { (statusCode, data, error) in

            guard let error = error else {
                completion(statusCode, data, nil)
                return
            }

            switch error.type {
            case .unauthorized:
                if let tokenRefresher = s.tokenRefresher {
                    tokenRefresher.refreshAuthToken(completion: { (error) in
                        if let error = error {
                            s.accountManager.logOut()
                            completion(statusCode, data, error)
                            return
                        }

                        s.networkWrapper.runRequest(request, baseURL: baseUrl, authToken: tokenString, progressResult: progressResult, completion: completion)
                    })
                    return
                }
            default:
                completion(statusCode, nil, error)
                break
            }
        }
    }
}
