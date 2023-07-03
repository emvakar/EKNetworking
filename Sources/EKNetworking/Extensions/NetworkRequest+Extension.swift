//
//  NetworkRequest+Extension.swift
//  EKNetworking
//
//  Created by Nikita Tatarnikov on 19.06.2023
//  Copyright © 2023 TAXCOM. All rights reserved.
//

import Foundation

public extension EKNetworkRequest {
    var needToCache: Bool {
        get { return false }
        set {}
    }
    
    var array: [[String: Any]]? {
        get { return nil }
        set {}
    }
}
