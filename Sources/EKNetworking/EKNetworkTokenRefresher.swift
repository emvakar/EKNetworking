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
