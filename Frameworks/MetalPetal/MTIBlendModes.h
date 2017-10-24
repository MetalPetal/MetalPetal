//
//  MTIBlendModes.h
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * MTIBlendMode NS_EXTENSIBLE_STRING_ENUM;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeNormal;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeMultiply;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeOverlay;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeScreen;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeHardLight;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeSoftLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDarken;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLighten;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColorDodge;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDifference;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeExclusion;

// nom-separable
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeHue;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeSaturation; // untested
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColor;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLuminosity; // untested

FOUNDATION_EXPORT NSArray<MTIBlendMode> * MTIBlendModeGetAllModes(void) NS_SWIFT_NAME(getter:MTIBlendMode.all());

FOUNDATION_EXPORT NSString * MTIBlendModeGetFragmentFunctionName(MTIBlendMode mode) NS_SWIFT_NAME(getter:MTIBlendMode.fragmentFunctionName(self:));

NS_ASSUME_NONNULL_END
