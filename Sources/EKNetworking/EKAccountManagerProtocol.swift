//
//  EKAccountManagerProtocol.swift
//  EKNetworking
//
//  Created by Emil Karimov on 06/06/2019.
//  Copyright © 2019 ESKARIA Corp. All rights reserved.
//

import Foundation

public protocol EKAccountManagerProtocol {
    func getBaseUrl() -> String
    func getMediaBaseUrl() -> String
    func getUserToken() -> String
    func setUserToken(newToken: String)
    func logOut()
    //func getRefreshToken() -> String
    //func setRefreshToken(newToken: String)
}
