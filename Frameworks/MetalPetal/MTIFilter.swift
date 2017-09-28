//
//  MTIFilter.swift
//  Pods
//
//  Created by YuAo on 22/09/2017.
//

import Foundation

extension MTIFilter {
    
    public var parameters: Dictionary<String, Any> {
        return MTIGetParametersDictionaryForFilter(self)
    }
    
}
