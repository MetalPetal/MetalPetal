//
//  MTIMPSSobelFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 11/12/2017.
//

#import <simd/simd.h>
#import "MTIFilter.h"

typedef NS_ENUM(NSUInteger, MTIMPSSobelColorMode) {
    MTIMPSSobelColorModeAuto,
    MTIMPSSobelColorModeGrayscale,
    MTIMPSSobelColorModeGrayscaleInverted
};

@interface MTIMPSSobelFilter : NSObject <MTIUnaryFilter>

@property (nonatomic, readonly) simd_float3 grayColorTransform;

- (instancetype)initWithGrayColorTransform:(simd_float3)grayColorTransform NS_DESIGNATED_INITIALIZER;

@property (nonatomic) MTIMPSSobelColorMode colorMode;

@end

