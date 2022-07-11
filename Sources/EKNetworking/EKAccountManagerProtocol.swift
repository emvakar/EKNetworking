//
//  EKAccountManagerProtocol.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

public enum AuthHeader: String, CaseIterable {
    case bearerToken = "Authorization"
    case sessionToken = "Session-Token"
}

public protocol EKAccountWriteProtocol {

    func set(baseUrl: String)
    func set(token: String?)
    func set(refresh token: String?)
    func logOut()

}

public protocol EKAccountReadProtocol {

    func getBaseUrl() -> String
    func getMediaBaseUrl() -> String
    func getToken() -> String?
    func getRefreshToken() -> String?
    func getAuthType() -> String?

}

extension EKAccountWriteProtocol {
    
    func set(baseUrl: String) { }
    
}
