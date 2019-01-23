//
//  MTIGeometry.h
//  Pods
//
//  Created by Yu Ao on 2018/5/6.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline;

@protocol MTIGeometry <NSObject, NSCopying>

- (void)encodeDrawCallWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
                          renderPipeline:(MTIRenderPipeline *)pipeline;

@end

NS_ASSUME_NONNULL_END

