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

__attribute__((objc_subclassing_restricted))
@interface MTIBlendFunctionDescriptors: NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptorForBlendFilter;

@property (nonatomic,copy,readonly,nullable) MTIFunctionDescriptor *fragmentFunctionDescriptorForMultilayerCompositingFilterWithProgrammableBlending;

@property (nonatomic,copy,readonly,nullable) MTIFunctionDescriptor *fragmentFunctionDescriptorForMultilayerCompositingFilterWithoutProgrammableBlending;

- (instancetype)initWithFragmentFunctionDescriptorForBlendFilter:(MTIFunctionDescriptor *)fragmentFunctionDescriptorForBlendFilter
fragmentFunctionDescriptorForMultilayerCompositingFilterWithProgrammableBlending:(nullable MTIFunctionDescriptor *)fragmentFunctionDescriptorForMultilayerCompositingFilterWithProgrammableBlending
fragmentFunctionDescriptorForMultilayerCompositingFilterWithoutProgrammableBlending:(nullable MTIFunctionDescriptor *)fragmentFunctionDescriptorForMultilayerCompositingFilterWithoutProgrammableBlending NS_DESIGNATED_INITIALIZER;

/// Creates a `MTIBlendFunctionDescriptors` using a metal shader function.
///
/// @discussion
/// The name of the function must be `blend`. The function must have exactly two arguments of type `float4`. The first argument represents the value of the backdrop pixel and the second represents the source pixel. The value returned by the function will be the new destination color. All colors should have unpremultiplied alpha component.
///
/// Example:
///
/// @textblock
/// float4 blend(float4 backdrop, float4 source) {
///     return float4(backdrop.rgb + source.rgb, 1.0);
/// }
/// @/textblock
///
/// You can optionally provide a `modify_source_texture_coordinates` function. This function is used to modify the sample coordinates of the source texture. It must have three arguments. The first argument represents the value of the backdrop pixel, the second represents the normalized sample coordinates for the source texture and the third position represents the pixel size of the source texture. The value returned by the function will be the new sample coordinates.
///
/// Example:
///
/// @textblock
/// float2 modify_source_texture_coordinates(float4 backdrop, float2 coordinates, uint2 source_texture_size) {
///     return coordinates;
/// }
///
/// float4 blend(float4 backdrop, float4 source) {
///     return float4(backdrop.rgb + source.rgb, 1.0);
/// }
/// @/textblock

- (instancetype)initWithBlendFormula:(NSString *)formula;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIBlendModes: NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly,class) NSArray<MTIBlendMode> *allModes NS_SWIFT_NAME(all);

+ (void)registerBlendMode:(MTIBlendMode)blendMode withFunctionDescriptors:(MTIBlendFunctionDescriptors *)functionDescriptors;

+ (void)unregisterBlendMode:(MTIBlendMode)blendMode;

+ (nullable MTIBlendFunctionDescriptors *)functionDescriptorsForBlendMode:(MTIBlendMode)blendMode NS_SWIFT_NAME(functionDescriptors(for:));

@end

NS_ASSUME_NONNULL_END
