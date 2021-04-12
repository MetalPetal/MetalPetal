//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipelineKernel;

__attribute__((objc_subclassing_restricted))
@interface MTIUnpremultiplyAlphaFilter : NSObject <MTIUnaryFilter>

@property (nonatomic, class, strong, readonly) MTIRenderPipelineKernel *kernel;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image outputPixelFormat:(MTLPixelFormat)pixelFormat;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIPremultiplyAlphaFilter : NSObject <MTIUnaryFilter>

@property (nonatomic, class, strong, readonly) MTIRenderPipelineKernel *kernel;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image outputPixelFormat:(MTLPixelFormat)pixelFormat;

@end

NS_ASSUME_NONNULL_END
