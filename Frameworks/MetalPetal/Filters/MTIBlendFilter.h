//
//  MTIBlendFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 12/10/2017.
//

#import "MTIFilter.h"
#import "MTIBlendModes.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIBlendFilter : NSObject <MTIFilter>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly) MTIBlendMode blendMode;

- (instancetype)initWithBlendMode:(MTIBlendMode)mode;

@property (nonatomic,strong,nullable) MTIImage *inputBackgroundImage;

@property (nonatomic,strong,nullable) MTIImage *inputImage;

@property (nonatomic) float intensity;

@end

NS_ASSUME_NONNULL_END
