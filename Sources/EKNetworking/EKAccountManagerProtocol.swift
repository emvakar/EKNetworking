//
//  EKAccountManagerProtocol.swift
//  EKNetworking
//
//  Created by Emil Karimov on 06/06/2019.
//  Copyright © 2019 ESKARIA Corp. All rights reserved.
//

import Foundation

public protocol EKAccountWriteProtocol {
    
    func set(token: String?)
    func set(refresh token: String?)
    func logOut()
    
}

public protocol EKAccountReadProtocol {
    
    func getBaseUrl() -> String
    func getMediaBaseUrl() -> String
    func getToken() -> String?
    func getRefreshToken() -> String?

}
