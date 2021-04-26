//
//  MTICornerRadius.h
//  Pods
//
//  Created by YuAo on 2021/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct MTICornerRadius {
    float topLeft;
    float topRight;
    float bottomRight;
    float bottomLeft;
};
typedef struct MTICornerRadius MTICornerRadius;

typedef NS_ENUM(NSInteger, MTICornerCurve) {
    MTICornerCurveCircular = 0,
    MTICornerCurveContinuous = 1
};

FOUNDATION_STATIC_INLINE __attribute__((__overloadable__)) NS_SWIFT_UNAVAILABLE("Use MTICornerRadius.init(topLeft:topRight:bottomRight:bottomLeft:)") MTICornerRadius MTICornerRadiusMake(float topLeft, float topRight, float bottomRight, float bottomLeft){
    MTICornerRadius radius;
    radius.topLeft = topLeft;
    radius.topRight = topRight;
    radius.bottomRight = bottomRight;
    radius.bottomLeft = bottomLeft;
    return radius;
}

FOUNDATION_STATIC_INLINE __attribute__((__overloadable__)) NS_SWIFT_NAME(MTICornerRadius.init(all:)) MTICornerRadius MTICornerRadiusMake(float r) {
    MTICornerRadius radius;
    radius.topLeft = r;
    radius.topRight = r;
    radius.bottomRight = r;
    radius.bottomLeft = r;
    return radius;
}

FOUNDATION_STATIC_INLINE NS_SWIFT_NAME(getter:MTICornerCurve.expansionFactor(self:)) float MTICornerCurveExpansionFactor(MTICornerCurve curve) {
    switch (curve) {
        case MTICornerCurveCircular:
            return 1.0;
        case MTICornerCurveContinuous:
            return 1.528665;
        default:
            return 1;
    }
}

NS_ASSUME_NONNULL_END
