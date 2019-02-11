//
//  MTIRGBColorSpaceConversionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/11.
//

#import "MTIUnaryImageRenderingFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTILinearToSRGBToneCurveFilter : MTIUnaryImageRenderingFilter

@end

@interface MTISRGBToneCurveToLinearFilter: MTIUnaryImageRenderingFilter

@end

NS_ASSUME_NONNULL_END
