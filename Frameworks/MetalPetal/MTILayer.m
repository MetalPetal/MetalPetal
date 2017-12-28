//
//  MTICompositingLayer.m
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import "MTILayer.h"
#import "MTIImage.h"

@implementation MTILayer

- (instancetype)initWithContent:(MTIImage *)content contentRegion:(CGRect)contentRegion compositingMask:(MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    return [self initWithContent:content contentIsFlipped:NO contentRegion:contentRegion compositingMask:compositingMask layoutUnit:layoutUnit position:position size:size rotation:rotation opacity:opacity blendMode:blendMode];
}

- (instancetype)initWithContent:(MTIImage *)content contentIsFlipped:(BOOL)contentIsFlipped contentRegion:(CGRect)contentRegion compositingMask:(MTIMask *)compositingMask layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    if (self = [super init]) {
        _content = content;
        _contentRegion = contentRegion;
        _contentIsFlipped = contentIsFlipped;
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

- (instancetype)initWithContent:(MTIImage *)content layoutUnit:(MTILayerLayoutUnit)layoutUnit position:(CGPoint)position size:(CGSize)size rotation:(float)rotation opacity:(float)opacity blendMode:(MTIBlendMode)blendMode {
    return [self initWithContent:content contentIsFlipped:NO contentRegion:content.extent compositingMask:nil layoutUnit:layoutUnit position:position size:size rotation:rotation opacity:opacity blendMode:blendMode];
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

@end
