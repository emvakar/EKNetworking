//
//  EKNetworkLogger.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

func ekNetworkLog(_ _class: AnyObject, _ _object: Any) {
    #if DEBUG
    let className = String(describing: _class).components(separatedBy: ".").last ?? ""
    let objectString = String(describing: _object)
    print("[DEBUG]: \(className): \(objectString)") // swiftlint:disable:this print_using
    #endif
}
