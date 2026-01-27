//
//  EKNetworkLoggerType.swift
//  EKNetworking
//
//  Created by Egor Solovev on 26.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

public enum EKNetworkLoggerType {
    case defaultLogger
    case sensitiveDataRedacted
    case customLogger(networkLogger: EKNetworkLoggerProtocol)
    
    var consoleLogEnable: Bool {
        switch self {
        case .defaultLogger, .sensitiveDataRedacted:
            return true
        case .customLogger:
            return false
        }
    }
    
    var redactSensitiveData: Bool {
        switch self {
        case .sensitiveDataRedacted:
            return true
        case .defaultLogger, .customLogger:
            return false
        }
    }
    
    var networkLogger: EKNetworkLoggerProtocol? {
        switch self {
        case .customLogger(let logger):
            return logger
        case .defaultLogger, .sensitiveDataRedacted:
            return nil
        }
    }
}
