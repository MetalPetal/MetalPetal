//
//  MTIBlendModes.m
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIBlendModes.h"

MTIBlendMode const MTIBlendModeNormal = @"Normal";
MTIBlendMode const MTIBlendModeMultiply = @"Multiply";
MTIBlendMode const MTIBlendModeOverlay = @"Overlay";
MTIBlendMode const MTIBlendModeScreen = @"Screen";
MTIBlendMode const MTIBlendModeHardLight = @"HardLight";

NSArray<MTIBlendMode> *MTIBlendModeGetAllModes(void) {
    return @[MTIBlendModeNormal, MTIBlendModeMultiply, MTIBlendModeHardLight];
}

NSString * MTIBlendModeGetFragmentFunctionName(MTIBlendMode mode) {
    NSCParameterAssert(mode.length > 0);
    return [[mode stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[mode substringWithRange:NSMakeRange(0, 1)].lowercaseString] stringByAppendingString:@"Blend"];
}
