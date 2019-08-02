//
//  MTICompositingLayer.m
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import "MTILayer.h"
#import "MTIImage.h"

MTIVerticeRegion MTIVerticeRegionIdentity(void)
{
    return MTIVerticeRegionMake(CGPointMake(0, 0), CGPointMake(1, 0), CGPointMake(0, 1), CGPointMake(1, 1));
}

MTIVerticeRegion MTIVerticeRegionMakeFromCGRect(CGRect frame)
{
    CGPoint tl = CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame));
    CGPoint tr = CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame));
    CGPoint bl = CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame));
    CGPoint br = CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame));
    return MTIVerticeRegionMake(tl, tr, bl, br);
}

MTIVerticeRegion MTIVerticeRegionMake(CGPoint tl, CGPoint tr, CGPoint bl, CGPoint br)
{
    return (MTIVerticeRegion){tl, tr, bl, br};
}

@implementation MTILayer

- (instancetype)initWithContent:(MTIImage *)content contentRegion:(CGRect)contentRegion contentFlipOptions:(MTILayerFlipOptions)contentFlipOptions compositingMask:(nullable MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    MTIVerticeRegion verticeRegion = MTIVerticeRegionMakeFromCGRect(CGRectMake(position.x - size.width * 0.5, position.y - size.height * 0.5, size.width, size.height));
    return [self initWithContent:content
                   verticeRegion:verticeRegion
                   contentRegion:contentRegion
              contentFlipOptions:contentFlipOptions
                 compositingMask:compositingMask
                      layoutUnit:layoutUnit
                        position:position
                            size:size
                        rotation:rotation
                         opacity:opacity
                       blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content contentRegion:(CGRect)contentRegion compositingMask:(MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    MTIVerticeRegion verticeRegion = MTIVerticeRegionMakeFromCGRect(CGRectMake(position.x - size.width * 0.5, position.y - size.height * 0.5, size.width, size.height));
    return [self initWithContent:content
                   verticeRegion:verticeRegion
                   contentRegion:contentRegion
              contentFlipOptions:MTILayerFlipOptionsDonotFlip
                 compositingMask:compositingMask
                      layoutUnit:layoutUnit
                        position:position
                            size:size
                        rotation:rotation
                         opacity:opacity
                       blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content contentIsFlipped:(BOOL)contentIsFlipped contentRegion:(CGRect)contentRegion compositingMask:(MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    MTIVerticeRegion verticeRegion = MTIVerticeRegionMakeFromCGRect(CGRectMake(position.x - size.width * 0.5, position.y - size.height * 0.5, size.width, size.height));
    return [self initWithContent:content
                   verticeRegion:verticeRegion
                   contentRegion:contentRegion
              contentFlipOptions:contentIsFlipped ? MTILayerFlipOptionsFlipVertically : MTILayerFlipOptionsDonotFlip
                 compositingMask:compositingMask
                      layoutUnit:layoutUnit
                        position:position
                            size:size
                        rotation:rotation
                         opacity:opacity
                       blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    MTIVerticeRegion verticeRegion = MTIVerticeRegionMakeFromCGRect(CGRectMake(position.x - size.width * 0.5, position.y - size.height * 0.5, size.width, size.height));
    return [self initWithContent:content
                   verticeRegion:verticeRegion
                   contentRegion:content.extent
              contentFlipOptions:MTILayerFlipOptionsDonotFlip
                 compositingMask:nil
                      layoutUnit:layoutUnit
                        position:position
                            size:size
                        rotation:rotation
                         opacity:opacity
                       blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content
                  verticeRegion:(MTIVerticeRegion)verticeRegion
                  contentRegion:(CGRect)contentRegion
                compositingMask:(nullable MTIMask *)compositingMask
                     layoutUnit:(MTILayerLayoutUnit)layoutUnit
                        opacity:(float)opacity
                      blendMode:(MTIBlendMode)blendMode {
    CGFloat minX = MIN(MIN(verticeRegion.tl.x, verticeRegion.bl.x), MIN(verticeRegion.tr.x, verticeRegion.br.x));
    CGFloat minY = MIN(MIN(verticeRegion.tl.y, verticeRegion.tr.y), MIN(verticeRegion.bl.y, verticeRegion.br.y));
    CGFloat maxX = MAX(MAX(verticeRegion.tl.x, verticeRegion.bl.x), MAX(verticeRegion.tr.x, verticeRegion.br.x));
    CGFloat maxY = MAX(MAX(verticeRegion.tl.y, verticeRegion.tr.y), MAX(verticeRegion.bl.y, verticeRegion.br.y));
    return [self initWithContent:content
                   verticeRegion:verticeRegion
                   contentRegion:content.extent
              contentFlipOptions:MTILayerFlipOptionsDonotFlip
                 compositingMask:compositingMask
                      layoutUnit:layoutUnit
                        position:CGPointMake((minX + maxX) * 0.5, (minY + maxY) * 0.5)
                            size:CGSizeMake(maxX - minX, maxY - minY)
                        rotation:0
                         opacity:opacity
                       blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content verticeRegion:(MTIVerticeRegion)verticeRegion contentRegion:(CGRect)contentRegion contentFlipOptions:(MTILayerFlipOptions)contentFlipOptions compositingMask:(MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    if (self = [super init]) {
        _content = content;
        _verticeRegion = verticeRegion;
        _contentRegion = contentRegion;
        _contentFlipOptions = contentFlipOptions;
        _compositingMask = compositingMask;
        _layoutUnit = layoutUnit;
        _position = position;
        _size = size;
        _rotation = rotation;
        _opacity = opacity;
        _blendMode = blendMode;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (CGSize)sizeInPixelForBackgroundSize:(CGSize)backgroundSize {
    switch (_layoutUnit) {
        case MTILayerLayoutUnitPixel:
            return _size;
        case MTILayerLayoutUnitFractionOfBackgroundSize:
            return CGSizeMake(backgroundSize.width * _size.width, backgroundSize.height * _size.height);
        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown MTILayerLayoutUnit" userInfo:@{@"Unit": @(_layoutUnit)}];
    }
}

- (CGPoint)positionInPixelForBackgroundSize:(CGSize)backgroundSize {
    switch (_layoutUnit) {
        case MTILayerLayoutUnitPixel:
            return _position;
        case MTILayerLayoutUnitFractionOfBackgroundSize:
            return CGPointMake(backgroundSize.width * _position.x, backgroundSize.height * _position.y);
        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown MTILayerLayoutUnit" userInfo:@{@"Unit": @(_layoutUnit)}];
    }
}

- (MTIVerticeRegion)verticeRegionInPixelForBackgroundSize:(CGSize)backgroundSize {
    switch (_layoutUnit) {
        case MTILayerLayoutUnitPixel: {
            return _verticeRegion;
        }
        case MTILayerLayoutUnitFractionOfBackgroundSize: {
            CGPoint tl = CGPointMake(backgroundSize.width * self.verticeRegion.tl.x, backgroundSize.width * self.verticeRegion.tl.y);
            CGPoint tr = CGPointMake(backgroundSize.width * self.verticeRegion.tr.x, backgroundSize.width * self.verticeRegion.tr.y);
            CGPoint bl = CGPointMake(backgroundSize.width * self.verticeRegion.bl.x, backgroundSize.height * self.verticeRegion.bl.y);
            CGPoint br = CGPointMake(backgroundSize.width * self.verticeRegion.br.x, backgroundSize.width * self.verticeRegion.br.y);
            return MTIVerticeRegionMake(tl, tr, bl, br);
        }
        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown MTILayerLayoutUnit" userInfo:@{@"Unit": @(_layoutUnit)}];
    }
}

@end
