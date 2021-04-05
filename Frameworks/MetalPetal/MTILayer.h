//
//  MTICompositingLayer.h
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import <CoreGraphics/CoreGraphics.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIBlendModes.h>
#import <MetalPetal/MTIColor.h>
#else
#import "MTIBlendModes.h"
#import "MTIColor.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIMask;

typedef NS_CLOSED_ENUM(NSInteger, MTILayerLayoutUnit) {
    MTILayerLayoutUnitPixel,
    MTILayerLayoutUnitFractionOfBackgroundSize
} NS_SWIFT_NAME(MTILayer.LayoutUnit);

typedef NS_OPTIONS(NSUInteger, MTILayerFlipOptions) {
    MTILayerFlipOptionsDonotFlip = 0,
    MTILayerFlipOptionsFlipVertically = 1 << 0,
    MTILayerFlipOptionsFlipHorizontally = 1 << 1,
} NS_SWIFT_NAME(MTILayer.FlipOptions);

/// A MTILayer represents a compositing layer for MTIMultilayerCompositingFilter. MTILayers use a UIKit like coordinate system.
__attribute__((objc_subclassing_restricted))
@interface MTILayer: NSObject <NSCopying>

@property (nonatomic, strong, readonly) MTIImage *content;

@property (nonatomic, readonly) CGRect contentRegion; //pixel

@property (nonatomic, readonly) MTILayerFlipOptions contentFlipOptions;

/// A mask that applies to the `content` of the layer. This mask is resized and aligned with the layer.
@property (nonatomic, strong, readonly, nullable) MTIMask *mask;

/// A mask that applies to the `content` of the layer. This mask is resized and aligned with the background.
@property (nonatomic, strong, readonly, nullable) MTIMask *compositingMask;

@property (nonatomic, readonly) MTILayerLayoutUnit layoutUnit;

@property (nonatomic, readonly) CGPoint position;

@property (nonatomic, readonly) CGSize size;

@property (nonatomic, readonly) float rotation; //rad

@property (nonatomic, readonly) float opacity;

/// Tint the content to with the color. If the tintColor's alpha is zero original content is rendered.
@property (nonatomic, readonly) MTIColor tintColor;

@property (nonatomic, copy, readonly) MTIBlendMode blendMode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContent:(MTIImage *)content
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      blendMode:(MTIBlendMode)blendMode;

- (instancetype)initWithContent:(MTIImage *)content
                  contentRegion:(CGRect)contentRegion
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      blendMode:(MTIBlendMode)blendMode;

- (instancetype)initWithContent:(MTIImage *)content
               contentIsFlipped:(BOOL)contentIsFlippedVertically
                  contentRegion:(CGRect)contentRegion
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      blendMode:(MTIBlendMode)blendMode __attribute__((deprecated("Replaced by MTILayer(content:contentRegion:contentFlipOptions:compositingMask:layoutUnit:position:size:rotation:opacity:blendMode:)")));;

- (instancetype)initWithContent:(MTIImage *)content
                  contentRegion:(CGRect)contentRegion
             contentFlipOptions:(MTILayerFlipOptions)contentFlipOptions
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      blendMode:(MTIBlendMode)blendMode;


- (instancetype)initWithContent:(MTIImage *)content
                  contentRegion:(CGRect)contentRegion
             contentFlipOptions:(MTILayerFlipOptions)contentFlipOptions
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      tintColor:(MTIColor)tintColor
                      blendMode:(MTIBlendMode)blendMode;

- (instancetype)initWithContent:(MTIImage *)content
                  contentRegion:(CGRect)contentRegion
             contentFlipOptions:(MTILayerFlipOptions)contentFlipOptions
                           mask:(nullable MTIMask *)mask
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(float)rotation
                        opacity:(float)opacity
                      tintColor:(MTIColor)tintColor
                      blendMode:(MTIBlendMode)blendMode NS_DESIGNATED_INITIALIZER;

- (CGSize)sizeInPixelForBackgroundSize:(CGSize)backgroundSize;

- (CGPoint)positionInPixelForBackgroundSize:(CGSize)backgroundSize;

@end

NS_ASSUME_NONNULL_END

