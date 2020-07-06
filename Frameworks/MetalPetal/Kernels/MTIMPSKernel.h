//
//  MTIMPSKernel.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIKernel.h>
#import <MetalPetal/MTITextureDimensions.h>
#else
#import "MTIKernel.h"
#import "MTITextureDimensions.h"
#endif

@class MTIAlphaTypeHandlingRule;

NS_ASSUME_NONNULL_BEGIN

@class MTIContext, MTIImage;

typedef MPSKernel * _Nonnull (^MTIMPSKernelBuilder)(id<MTLDevice> device);

__attribute__((objc_subclassing_restricted))
@interface MTIMPSKernel : NSObject <MTIKernel>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly) MTIAlphaTypeHandlingRule *alphaTypeHandlingRule;

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder NS_SWIFT_NAME(init(builder:));

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder alphaTypeHandlingRule:(MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(builder:alphaTypeHandlingRule:));

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

NS_ASSUME_NONNULL_END
