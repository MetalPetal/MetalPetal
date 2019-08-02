//
//  MTIGeometry.h
//  Pods
//
//  Created by Yu Ao on 2018/5/6.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline;

@protocol MTIGeometryRenderingContext <NSObject>

@property (nonatomic, readonly, strong) MTIRenderPipeline *renderPipeline;

@property (nonatomic, readonly, strong) id<MTLDevice> device;

@end

@protocol MTIGeometry <NSObject, NSCopying>

- (void)encodeDrawCallWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
                                 context:(id<MTIGeometryRenderingContext>)context;

@end

NS_ASSUME_NONNULL_END


#import "MTIRenderPipeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIRenderPipeline (MTIGeometryRenderingContext) <MTIGeometryRenderingContext>

@end

NS_ASSUME_NONNULL_END
