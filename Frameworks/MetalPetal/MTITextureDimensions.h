//
//  MTITextureDimensions.h
//  Pods
//
//  Created by Yu Ao on 11/10/2017.
//

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

struct MTITextureDimensions {
    NSUInteger width;
    NSUInteger height;
    NSUInteger depth;
};
typedef struct MTITextureDimensions MTITextureDimensions;

NS_INLINE NS_SWIFT_NAME(MTITextureDimensions.init(cgSize:)) MTITextureDimensions MTITextureDimensionsMake2DFromCGSize(CGSize size) {
    return (MTITextureDimensions){.width = (NSUInteger)size.width, .height = (NSUInteger)size.height, .depth = 1};
}

NS_INLINE NS_SWIFT_NAME(MTITextureDimensions.isEqual(self:to:)) BOOL MTITextureDimensionsEqualToTextureDimensions(MTITextureDimensions a, MTITextureDimensions b) {
    return a.width == b.width && a.height == b.height && a.depth == b.depth;
}

NS_ASSUME_NONNULL_END
