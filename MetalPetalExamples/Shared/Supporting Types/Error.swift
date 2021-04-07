//
//  Error.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/5.
//

import Foundation

struct DescriptiveError: LocalizedError {
    let errorDescription: String?
    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
