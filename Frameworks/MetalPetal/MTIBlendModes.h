//
//  MTIBlendModes.h
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Modes that describe how source colors blend with destination colors. See also: https://www.w3.org/TR/compositing-1/
typedef NSString * MTIBlendMode NS_EXTENSIBLE_STRING_ENUM;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeNormal;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDarken;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeMultiply;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColorBurn;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLinearBurn;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDarkerColor;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLighten;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeScreen;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColorDodge;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeAdd; // also LinearDodge
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLighterColor;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeOverlay;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeSoftLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeHardLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeVividLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLinearLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModePinLight;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeHardMix;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDifference;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeExclusion;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeSubtract;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeDivide;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeHue;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeSaturation;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColor;
FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeLuminosity;

FOUNDATION_EXPORT MTIBlendMode const MTIBlendModeColorLookup512x512;

@class MTIFunctionDescriptor;

@interface MTIBlendFunctionDescriptors: NSObject <NSCopying>

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptorForBlendFilter;

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptorForMultilayerCompositingFilter;

- (instancetype)initWithFragmentFunctionDescriptorForBlendFilter:(MTIFunctionDescriptor *)fragmentFunctionDescriptorForBlendFilter
        fragmentFunctionDescriptorForMultilayerCompositingFilter:(MTIFunctionDescriptor *)fragmentFunctionDescriptorForMultilayerCompositingFilter;

@end

@interface MTIBlendModes: NSObject

@property (nonatomic,copy,readonly,class) NSArray<MTIBlendMode> *allModes NS_SWIFT_NAME(all);

+ (void)registerBlendMode:(MTIBlendMode)blendMode withFunctionDescriptors:(MTIBlendFunctionDescriptors *)functionDescriptors;

+ (nullable MTIBlendFunctionDescriptors *)functionDescriptorsForBlendMode:(MTIBlendMode)blendMode NS_SWIFT_NAME(functionDescriptors(for:));

@end

NS_ASSUME_NONNULL_END
