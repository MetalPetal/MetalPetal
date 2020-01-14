//
//  MTIBlendModes.m
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIBlendModes.h"

MTIBlendMode const MTIBlendModeNormal = @"Normal";

MTIBlendMode const MTIBlendModeDarken = @"Darken";
MTIBlendMode const MTIBlendModeMultiply = @"Multiply";
MTIBlendMode const MTIBlendModeColorBurn = @"ColorBurn";
MTIBlendMode const MTIBlendModeLinearBurn = @"LinearBurn";
MTIBlendMode const MTIBlendModeDarkerColor = @"DarkerColor";

MTIBlendMode const MTIBlendModeLighten = @"Lighten";
MTIBlendMode const MTIBlendModeScreen = @"Screen";
MTIBlendMode const MTIBlendModeColorDodge = @"ColorDodge";
MTIBlendMode const MTIBlendModeAdd = @"Add"; // LinearDodge
MTIBlendMode const MTIBlendModeLighterColor = @"LighterColor";

MTIBlendMode const MTIBlendModeOverlay = @"Overlay";
MTIBlendMode const MTIBlendModeHardMix = @"HardMix";

MTIBlendMode const MTIBlendModeSoftLight = @"SoftLight";
MTIBlendMode const MTIBlendModeHardLight = @"HardLight";
MTIBlendMode const MTIBlendModeVividLight = @"VividLight";
MTIBlendMode const MTIBlendModeLinearLight = @"LinearLight";
MTIBlendMode const MTIBlendModePinLight = @"PinLight";

MTIBlendMode const MTIBlendModeDifference = @"Difference";
MTIBlendMode const MTIBlendModeExclusion = @"Exclusion";
MTIBlendMode const MTIBlendModeSubtract = @"Subtract";
MTIBlendMode const MTIBlendModeDivide = @"Divide";

MTIBlendMode const MTIBlendModeHue = @"Hue";
MTIBlendMode const MTIBlendModeSaturation = @"Saturation";
MTIBlendMode const MTIBlendModeColor = @"Color";
MTIBlendMode const MTIBlendModeLuminosity = @"Luminosity";

MTIBlendMode const MTIBlendModeColorLookup512x512 = @"ColorLookup512x512";

@implementation MTIBlendFunctionDescriptors

- (instancetype)initWithFragmentFunctionDescriptorForBlendFilter:(MTIFunctionDescriptor *)fragmentFunctionDescriptorForBlendFilter
        fragmentFunctionDescriptorForMultilayerCompositingFilter:(MTIFunctionDescriptor *)fragmentFunctionDescriptorForMultilayerCompositingFilter {
    if (self = [super init]) {
        _fragmentFunctionDescriptorForBlendFilter = fragmentFunctionDescriptorForBlendFilter;
        _fragmentFunctionDescriptorForMultilayerCompositingFilter = fragmentFunctionDescriptorForMultilayerCompositingFilter;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

#import "MTILock.h"
#import "MTIFunctionDescriptor.h"

@implementation MTIBlendModes

static NSDictionary<MTIBlendMode, MTIBlendFunctionDescriptors *> *_registeredBlendModes;
static id<NSLocking> _registeredBlendModesLock;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<MTIBlendMode> *builtinModes = @[MTIBlendModeNormal,
                                                MTIBlendModeDarken,
                                                MTIBlendModeMultiply,
                                                MTIBlendModeColorBurn,
                                                MTIBlendModeLinearBurn,
                                                MTIBlendModeDarkerColor,
                                                MTIBlendModeLighten,
                                                MTIBlendModeScreen,
                                                MTIBlendModeColorDodge,
                                                MTIBlendModeAdd,
                                                MTIBlendModeLighterColor,
                                                MTIBlendModeOverlay,
                                                MTIBlendModeHardMix,
                                                MTIBlendModeSoftLight,
                                                MTIBlendModeHardLight,
                                                MTIBlendModeLinearLight,
                                                MTIBlendModeVividLight,
                                                MTIBlendModePinLight,
                                                MTIBlendModeDifference,
                                                MTIBlendModeExclusion,
                                                MTIBlendModeSubtract,
                                                MTIBlendModeDivide,
                                                MTIBlendModeHue,
                                                MTIBlendModeColor,
                                                MTIBlendModeSaturation,
                                                MTIBlendModeLuminosity,
                                                MTIBlendModeColorLookup512x512
                                                ];
        NSMutableDictionary *modes = [NSMutableDictionary dictionary];
        for (MTIBlendMode mode in builtinModes) {
            NSString *fragmentFunctionNameForBlendFilter = [[mode stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[mode substringWithRange:NSMakeRange(0, 1)].lowercaseString] stringByAppendingString:@"Blend"];
            NSString *fragmentFunctionNameForMultilayerCompositingFilter = [NSString stringWithFormat:@"multilayerComposite%@Blend",mode];
            MTIBlendFunctionDescriptors *descriptors = [[MTIBlendFunctionDescriptors alloc] initWithFragmentFunctionDescriptorForBlendFilter:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionNameForBlendFilter]
                                                                                    fragmentFunctionDescriptorForMultilayerCompositingFilter:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionNameForMultilayerCompositingFilter]];
            modes[mode] = descriptors;
        }
        _registeredBlendModes = [modes copy];
        _registeredBlendModesLock = MTILockCreate();
    });
}

+ (NSArray<MTIBlendMode> *)allModes {
    [_registeredBlendModesLock lock];
    NSArray<MTIBlendMode> *allModes = _registeredBlendModes.allKeys;
    [_registeredBlendModesLock unlock];
    return allModes;
}

+ (void)registerBlendMode:(MTIBlendMode)blendMode withFunctionDescriptors:(MTIBlendFunctionDescriptors *)functionDescriptors {
    NSParameterAssert(blendMode);
    NSParameterAssert(functionDescriptors);
    
    [_registeredBlendModesLock lock];
    NSParameterAssert(_registeredBlendModes[blendMode] == nil);
    NSMutableDictionary *modes = [NSMutableDictionary dictionaryWithDictionary:_registeredBlendModes];
    modes[blendMode] = functionDescriptors;
    _registeredBlendModes = [modes copy];
    [_registeredBlendModesLock unlock];
}

+ (MTIBlendFunctionDescriptors *)functionDescriptorsForBlendMode:(MTIBlendMode)blendMode {
    [_registeredBlendModesLock lock];
    MTIBlendFunctionDescriptors *functionDescriptors = _registeredBlendModes[blendMode];
    [_registeredBlendModesLock unlock];
    return functionDescriptors;
}

@end
