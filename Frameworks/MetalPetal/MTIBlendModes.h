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

FOUNDATION_EXPORT NSArray<MTIBlendMode> * MTIBlendModeGetAllModes(void) NS_SWIFT_NAME(getter:MTIBlendMode.all());

FOUNDATION_EXPORT NSString * MTIBlendModeGetFragmentFunctionName(MTIBlendMode mode) NS_SWIFT_NAME(getter:MTIBlendMode.fragmentFunctionName(self:));

NS_ASSUME_NONNULL_END
