//
//  MTIMPSSobelFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 11/12/2017.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

typedef NS_ENUM(NSUInteger, MTIMPSSobelColorMode) {
    MTIMPSSobelColorModeAuto,
    MTIMPSSobelColorModeGrayscale,
    MTIMPSSobelColorModeGrayscaleInverted
};

__attribute__((objc_subclassing_restricted))
@interface MTIMPSSobelFilter : NSObject <MTIUnaryFilter>

@property (nonatomic, readonly) simd_float3 grayColorTransform;

- (instancetype)initWithGrayColorTransform:(simd_float3)grayColorTransform NS_DESIGNATED_INITIALIZER;

@property (nonatomic) MTIMPSSobelColorMode colorMode;

@end

