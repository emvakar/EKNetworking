//
//  HTTPURLResponse+Extension.swift
//  EKNetworking
//
//  Created by Egor Solovev on 15.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

public extension HTTPURLResponse {
    
    /// Convenience property for accessing HTTP headers as [String: String]
    /// Provides backward compatibility with Moya/Alamofire's HTTPURLResponse.headers extension
    var headers: [String: String] {
        var stringHeaders: [String: String] = [:]
        for (key, value) in allHeaderFields {
            if let keyString = key as? String, let valueString = value as? String {
                stringHeaders[keyString] = valueString
            }
        }
        return stringHeaders
    }
}
