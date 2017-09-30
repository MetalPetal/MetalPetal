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
