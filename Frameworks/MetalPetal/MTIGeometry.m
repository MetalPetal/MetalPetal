//
//  MTIGeometry.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/2.
//

#import "MTIGeometry.h"

@implementation MTIRenderPipeline (MTIGeometryRenderingContext)

- (MTIRenderPipeline *)renderPipeline {
    return self;
}

- (id<MTLDevice>)device {
    return self.state.device;
}

@end
