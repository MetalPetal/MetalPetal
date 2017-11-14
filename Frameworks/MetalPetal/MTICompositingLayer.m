//
//  MTICompositingLayer.m
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import "MTICompositingLayer.h"
#import "MTIImage.h"

@implementation MTICompositingLayer

- (instancetype)initWithContent:(MTIImage *)content contentRegion:(CGRect)contentRegion compositingMask:(MTIImage *)compositingMask position:(CGPoint)position size:(CGSize)size rotation:(CGFloat)rotation opacity:(CGFloat)opacity blendMode:(MTIBlendMode)blendMode {
    if (self = [super init]) {
        _content = content;
        _contentRegion = contentRegion;
        _compositingMask = compositingMask;
        _position = position;
        _size = size;
        _rotation = rotation;
        _opacity = opacity;
        _blendMode = blendMode;
    }
    return self;
}

- (instancetype)initWithContent:(MTIImage *)content position:(CGPoint)position size:(CGSize)size rotation:(CGFloat)rotation opacity:(CGFloat)opacity blendMode:(MTIBlendMode)blendMode {
    return [self initWithContent:content contentRegion:content.extent compositingMask:nil position:position size:size rotation:rotation opacity:opacity blendMode:blendMode];
}

@end
