//
//  MTIImage+Filters.h
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIFilter.h"
#import "MTIImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIImage (Filters)

- (MTIImage *)imageByUnpremultiplyingAlpha;

- (MTIImage *)imageByPremultiplyingAlpha;

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation NS_SWIFT_NAME(oriented(_:));

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation outputPixelFormat:(MTLPixelFormat)pixelFormat NS_SWIFT_NAME(oriented(_:outputPixelFormat:));

@end

NS_ASSUME_NONNULL_END
