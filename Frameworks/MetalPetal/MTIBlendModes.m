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

MTIBlendMode const MTIBlendModeAdd = @"Add";

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
                                                MTIBlendModeMultiply,
                                                MTIBlendModeHardLight,
                                                MTIBlendModeScreen,
                                                MTIBlendModeOverlay,
                                                MTIBlendModeSoftLight,
                                                MTIBlendModeDarken,
                                                MTIBlendModeLighten,
                                                MTIBlendModeColorDodge,
                                                MTIBlendModeColorBurn,
                                                MTIBlendModeDifference,
                                                MTIBlendModeExclusion,
                                                MTIBlendModeHue,
                                                MTIBlendModeColor,
                                                MTIBlendModeSaturation,
                                                MTIBlendModeLuminosity,
                                                MTIBlendModeAdd];
        NSMutableDictionary *modes = [NSMutableDictionary dictionary];
        for (MTIBlendMode mode in builtinModes) {
            NSString *fragmentFunctionNameForBlendFilter = [[mode stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[mode substringWithRange:NSMakeRange(0, 1)].lowercaseString] stringByAppendingString:@"Blend"];
            MTIBlendFunctionDescriptors *descriptors = [[MTIBlendFunctionDescriptors alloc] initWithFragmentFunctionDescriptorForBlendFilter:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionNameForBlendFilter]
                                                                                    fragmentFunctionDescriptorForMultilayerCompositingFilter:[[MTIFunctionDescriptor alloc] initWithName:[NSString stringWithFormat:@"multilayerComposite%@Blend",mode]]];
            modes[mode] = descriptors;
        }

        MTIBlendFunctionDescriptors *colorLookup512x512BlendDescriptor = [[MTIBlendFunctionDescriptors alloc] initWithFragmentFunctionDescriptorForBlendFilter:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookup512x512Blend"] fragmentFunctionDescriptorForMultilayerCompositingFilter:[[MTIFunctionDescriptor alloc] initWithName:@"multilayerCompositeColorLookup512x512Blend"]];
        modes[MTIBlendModeColorLookup512x512] = colorLookup512x512BlendDescriptor;
        
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
