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

MTIBlendMode const MTIBlendModeSoftLight = @"SoftLight";
MTIBlendMode const MTIBlendModeDarken = @"Darken";
MTIBlendMode const MTIBlendModeLighten = @"Lighten";
MTIBlendMode const MTIBlendModeColorDodge = @"ColorDodge";
MTIBlendMode const MTIBlendModeColorBurn = @"ColorBurn";
MTIBlendMode const MTIBlendModeDifference = @"Difference";
MTIBlendMode const MTIBlendModeExclusion = @"Exclusion";

MTIBlendMode const MTIBlendModeHue = @"Hue";
MTIBlendMode const MTIBlendModeSaturation = @"Saturation";
MTIBlendMode const MTIBlendModeColor = @"Color";
MTIBlendMode const MTIBlendModeLuminosity = @"Luminosity";

NSArray<MTIBlendMode> *MTIBlendModeGetAllModes(void) {
    return @[MTIBlendModeNormal, MTIBlendModeMultiply, MTIBlendModeHardLight, MTIBlendModeScreen, MTIBlendModeOverlay, MTIBlendModeSoftLight, MTIBlendModeDarken, MTIBlendModeLighten, MTIBlendModeColorDodge, MTIBlendModeColorBurn, MTIBlendModeDifference, MTIBlendModeExclusion, MTIBlendModeHue, MTIBlendModeColor, MTIBlendModeSaturation, MTIBlendModeLuminosity];
}

NSString * MTIBlendModeGetFragmentFunctionName(MTIBlendMode mode) {
    NSCParameterAssert(mode.length > 0);
    return [[mode stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[mode substringWithRange:NSMakeRange(0, 1)].lowercaseString] stringByAppendingString:@"Blend"];
}
