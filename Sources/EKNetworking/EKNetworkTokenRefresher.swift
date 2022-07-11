//
//  EKNetworkTokenRefresher.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public protocol EKNetworkTokenRefresherProtocol {

    // Обновление токена при 401 ошибке
    func refreshAuthToken(completion: @escaping (EKNetworkError?) -> Void)

    // Обновление токена при 5012 ошибке для ДСС токена
    func refreshDSSAuthToken(completion: @escaping (EKNetworkError?) -> Void)

}

extension EKNetworkTokenRefresherProtocol {

    // Дефолтная реализация обновление токена ДСС
    func refreshDSSAuthToken(completion: @escaping (EKNetworkError?) -> Void) { completion(nil) }

}
