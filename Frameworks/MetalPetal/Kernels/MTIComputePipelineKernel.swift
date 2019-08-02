//
//  MTIComputePipelineKernel.swift
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/26.
//

import Foundation

extension MTIComputeFunctionDispatchOptions {
    public convenience init(_ generator: @escaping (_ pipelineState: MTLComputePipelineState) -> (threads: MTLSize, threadgroups: MTLSize, threadsPerThreadgroup: MTLSize)) {
        self.init(__generator: { pipelineState, threadsPtr, threadgroupsPtr, threadsPerThreadgroupPtr in
            let results = generator(pipelineState)
            threadsPtr.pointee = results.threads
            threadgroupsPtr.pointee = results.threadgroups
            threadsPerThreadgroupPtr.pointee = results.threadsPerThreadgroup
        })
    }
}
