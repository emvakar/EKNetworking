//
//  File.swift
//  
//
//  Created by Emil Karimov on 26.11.2020.
//

import Foundation

func ekNetworkLog(_ _class: AnyObject, _ _object: Any) {
    #if DEBUG
    let className = String(describing: _class).components(separatedBy: ".").last ?? ""
    let objectString = String(describing: _object)
    print("[DEBUG]: \(className): \(objectString)")
    #endif
}

