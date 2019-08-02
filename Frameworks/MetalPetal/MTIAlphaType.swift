//
//  MTIAlphaType.swift
//  MetalPetal
//
//  Created by Yu Ao on 23/10/2017.
//

import Foundation

extension MTIAlphaTypeHandlingRule {
    
    public var acceptableAlphaTypes: [MTIAlphaType] {
        return self.__acceptableAlphaTypes.compactMap({ value in
            return MTIAlphaType(rawValue: value.intValue)
        })
    }
    
    public convenience init(acceptableAlphaTypes: [MTIAlphaType], outputAlphaType: MTIAlphaType) {
        self.init(__acceptableAlphaTypes: acceptableAlphaTypes.map({ NSNumber(value: $0.rawValue) }), outputAlphaType: outputAlphaType)
    }
    
    public func outputAlphaType(forInputAlphaTypes inputAlphaTypes: [MTIAlphaType]) -> MTIAlphaType {
        return self.__outputAlphaType(forInputAlphaTypes: inputAlphaTypes.map({ NSNumber(value: $0.rawValue) }))
    }
    
}

extension MTIAlphaType: CustomStringConvertible {
    
    public var description: String {
        return MTIAlphaTypeGetDescription(self)
    }
    
}
