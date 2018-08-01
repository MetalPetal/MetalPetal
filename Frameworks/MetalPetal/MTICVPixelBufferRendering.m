//
//  MTICVPixelBufferRendering.m
//  MetalPetal
//
//  Created by Yu Ao on 08/04/2018.
//

#import "MTICVPixelBufferRendering.h"

@implementation MTICVPixelBufferRenderingOptions

- (instancetype)initWithRenderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI sRGB:(BOOL)sRGB {
    if (self = [super init]) {
        _renderingAPI = renderingAPI;
        _sRGB = sRGB;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (MTICVPixelBufferRenderingOptions *)defaultOptions {
    static MTICVPixelBufferRenderingOptions *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [[MTICVPixelBufferRenderingOptions alloc] initWithRenderingAPI:MTICVPixelBufferRenderingAPIDefault sRGB:NO];
    });
    return options;
}

@end
