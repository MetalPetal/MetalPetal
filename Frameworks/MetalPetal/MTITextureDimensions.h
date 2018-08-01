//
//  MTITextureDimensions.h
//  Pods
//
//  Created by Yu Ao on 11/10/2017.
//

#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

struct MTITextureDimensions {
    NSUInteger width;
    NSUInteger height;
    NSUInteger depth;
};
typedef struct MTITextureDimensions MTITextureDimensions;

FOUNDATION_EXPORT MTITextureDimensions MTITextureDimensionsMake2DFromCGSize(CGSize size) NS_SWIFT_NAME(MTITextureDimensions.init(cgSize:));

FOUNDATION_EXPORT BOOL MTITextureDimensionsEqualToTextureDimensions(MTITextureDimensions a, MTITextureDimensions b) NS_SWIFT_NAME(MTITextureDimensions.isEqual(self:to:));

NS_ASSUME_NONNULL_END
