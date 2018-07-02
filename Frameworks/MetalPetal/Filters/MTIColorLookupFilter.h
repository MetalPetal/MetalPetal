//
//  MTILookUpTableFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/12.
//

#import <CoreGraphics/CoreGraphics.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTIColorLookupTableType) {
    MTIColorLookupTableTypeUnknown,
    
    /// The look up table contents must a 2D image representing `n` slices of a unit color cube texture, arranged in an square of `n` images. For instance, a color cube of dimension 64x64x64 should be provided as an image of size 512x512 - sqrt(64x64x64).
    MTIColorLookupTableType2DSquare,
    
    /// The look up table contents must a 2D image representing `n` slices of a unit color cube texture, arranged in an horizontal row of `n` images. For instance, a color cube of dimension 16x16x16 should be provided as an image of size 256x16.
    MTIColorLookupTableType2DHorizontalStrip,
    
    MTIColorLookupTableType2DVerticalStrip,
    
    MTIColorLookupTableType3D
};

@interface MTIColorLookupTableInfo: NSObject <NSCopying>

@property (nonatomic,readonly) MTIColorLookupTableType type;

@property (nonatomic,readonly) NSInteger dimension;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithType:(MTIColorLookupTableType)type dimension:(NSInteger)dimension NS_DESIGNATED_INITIALIZER;

@end

@interface MTIColorLookupFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputColorLookupTable;

@property (nonatomic, strong, nullable, readonly) MTIColorLookupTableInfo *inputColorLookupTableInfo;

@property (nonatomic) float intensity;

+ (nullable MTIImage *)create3DColorLookupTableFrom2DColorLookupTable:(MTIImage *)image pixelFormat:(MTLPixelFormat)pixelFormat NS_SWIFT_NAME(make3DColorLookupTable(from:pixelFormat:));

@end

NS_ASSUME_NONNULL_END
