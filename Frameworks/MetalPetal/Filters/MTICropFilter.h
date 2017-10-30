//
//  MTICropFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//


#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MTICropRegionUnit) {
    MTICropRegionUnitPixel,
    MTICropRegionUnitPercentage
};

struct MTICropRegion {
    CGRect bounds;
    MTICropRegionUnit unit;
};
typedef struct MTICropRegion MTICropRegion;

FOUNDATION_EXPORT MTICropRegion MTICropRegionMake(CGRect rect, MTICropRegionUnit unit) NS_SWIFT_UNAVAILABLE("Use MTICropRegion.init instead.");

@interface MTICropFilter : NSObject <MTIFilter>

@property (nonatomic) MTICropRegion cropRegion;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end

NS_ASSUME_NONNULL_END
