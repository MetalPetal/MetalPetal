//
//  MTICompositingLayer.h
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MTIBlendModes.h"
#import "MTIColor.h"
#import "MTIMask.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIImage;

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
@interface MTILayer: NSObject <NSCopying>

@property (nonatomic, strong, readonly) MTIImage *content;

@property (nonatomic, readonly) CGRect contentRegion; //pixel

@property (nonatomic, readonly) MTILayerFlipOptions contentFlipOptions;

@property (nonatomic, strong, readonly, nullable) MTIMask *compositingMask;

@property (nonatomic, readonly) MTILayerLayoutUnit layoutUnit;

@property (nonatomic, readonly) CGPoint position;

@property (nonatomic, readonly) CGSize size;

@property (nonatomic, readonly) float rotation; //rad

@property (nonatomic, readonly) float opacity;

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
                      blendMode:(MTIBlendMode)blendMode NS_DESIGNATED_INITIALIZER;

- (CGSize)sizeInPixelForBackgroundSize:(CGSize)backgroundSize;

- (CGPoint)positionInPixelForBackgroundSize:(CGSize)backgroundSize;

@end

NS_ASSUME_NONNULL_END

