//
//  MTICropFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import <CoreGraphics/CoreGraphics.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MTICropRegionUnit) {
    MTICropRegionUnitPixel,
    MTICropRegionUnitPercentage
};

// Rounding policies:
//
// Original Value  1.2 | 1.21 | 1.25 | 1.35 | 1.27
// -----------------------------------------------
// Plain           1.2 | 1.2  | 1.3  | 1.4  | 1.3
// Floor           1.2 | 1.2  | 1.2  | 1.3  | 1.2
// Ceiling         1.2 | 1.3  | 1.3  | 1.4  | 1.3

typedef NS_ENUM(NSUInteger, MTICropFilterRoundingMode) {
    MTICropFilterRoundingModePlain,
    MTICropFilterRoundingModeCeiling,
    MTICropFilterRoundingModeFloor
};

struct MTICropRegion {
    CGRect bounds;
    MTICropRegionUnit unit;
};
typedef struct MTICropRegion MTICropRegion;

FOUNDATION_EXPORT MTICropRegion MTICropRegionMake(CGRect rect, MTICropRegionUnit unit) NS_SWIFT_UNAVAILABLE("Use MTICropRegion.init instead.");

@interface MTICropFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) MTICropRegion cropRegion;

@property (nonatomic) float scale;

@property (nonatomic) MTICropFilterRoundingMode roundingMode;

@end

NS_ASSUME_NONNULL_END
