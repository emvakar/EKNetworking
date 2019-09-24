//
//  EKNetworkTokenRefresher.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public protocol EKNetworkTokenRefresherProtocol {
    func refreshAuthToken(completion: @escaping (EKNetworkError?) -> Void)
}

public class EKNetworkTokenRefresher: EKNetworkTokenRefresherProtocol {

    private let accountManager: EKAccountManagerProtocol

    public init(accountManager: EKAccountManagerProtocol) {
        self.accountManager = accountManager
    }

    public func refreshAuthToken(completion: @escaping (EKNetworkError?) -> Void) {
        let error = EKNetworkErrorStruct(error: NSError(domain: "can do it", code: 10008, userInfo: nil))
        completion(error)
//        // TODO: - сделать рефрештокен
    }
}
