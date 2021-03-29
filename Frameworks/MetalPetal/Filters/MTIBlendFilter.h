//
//  MTIBlendFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 12/10/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#import <MetalPetal/MTIBlendModes.h>
#import <MetalPetal/MTIAlphaType.h>
#else
#import "MTIFilter.h"
#import "MTIBlendModes.h"
#import "MTIAlphaType.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIBlendFilter : NSObject <MTIFilter>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly) MTIBlendMode blendMode;

- (instancetype)initWithBlendMode:(MTIBlendMode)mode;

@property (nonatomic,strong,nullable) MTIImage *inputBackgroundImage;

@property (nonatomic,strong,nullable) MTIImage *inputImage;

/// Specifies the intensity (in the range [0, 1]) of the operation.
@property (nonatomic) float intensity;

/// Specifies the alpha type of output image. If `.alphaIsOne` is assigned, the alpha channel of the output image will be set to 1. The default value for this property is `.nonPremultiplied`.
@property (nonatomic) MTIAlphaType outputAlphaType;

@end

NS_ASSUME_NONNULL_END
