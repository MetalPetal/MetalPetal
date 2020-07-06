//
//  MTIImage+Filters.h
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#import <MetalPetal/MTIImage.h>
#else
#import "MTIFilter.h"
#import "MTIImage.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MTIImage (Filters)

- (MTIImage *)imageByUnpremultiplyingAlpha;

- (MTIImage *)imageByPremultiplyingAlpha;

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation NS_SWIFT_NAME(oriented(_:));

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation outputPixelFormat:(MTLPixelFormat)pixelFormat NS_SWIFT_NAME(oriented(_:outputPixelFormat:));

@end

NS_ASSUME_NONNULL_END
