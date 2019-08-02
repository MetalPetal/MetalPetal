//
//  MTIRenderPipelineOutputDescriptor.m
//  Pods
//
//  Created by YuAo on 18/11/2017.
//

#import "MTIRenderPassOutputDescriptor.h"
#import "MTIHasher.h"

@implementation MTIRenderPassOutputDescriptor

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat {
    return [self initWithDimensions:dimensions pixelFormat:pixelFormat loadAction:MTLLoadActionDontCare];
}

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction {
    return [self initWithDimensions:dimensions pixelFormat:pixelFormat loadAction:loadAction storeAction:MTLStoreActionStore];
}

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction storeAction:(MTLStoreAction)storeAction {
    return [self initWithDimensions:dimensions pixelFormat:pixelFormat clearColor:MTLClearColorMake(0, 0, 0, 0) loadAction:loadAction storeAction:storeAction];
}

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat clearColor:(MTLClearColor)clearColor loadAction:(MTLLoadAction)loadAction storeAction:(MTLStoreAction)storeAction {
    if (self = [super init]) {
        _dimensions = dimensions;
        _pixelFormat = pixelFormat;
        _loadAction = loadAction;
        _storeAction = storeAction;
        _clearColor = clearColor;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _dimensions.width);
    MTIHasherCombine(&hasher, _dimensions.height);
    MTIHasherCombine(&hasher, _dimensions.depth);
    MTIHasherCombine(&hasher, _pixelFormat);
    MTIHasherCombine(&hasher, _loadAction);
    MTIHasherCombine(&hasher, _storeAction);
    MTIHasherCombine(&hasher, _clearColor.red);
    MTIHasherCombine(&hasher, _clearColor.green);
    MTIHasherCombine(&hasher, _clearColor.blue);
    MTIHasherCombine(&hasher, _clearColor.alpha);
    return MTIHasherFinalize(&hasher);
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MTIRenderPassOutputDescriptor class]]) {
        return [self isEqualToOutputDescriptor:object];
    }
    return NO;
}

- (BOOL)isEqualToOutputDescriptor:(MTIRenderPassOutputDescriptor *)object {
    return MTITextureDimensionsEqualToTextureDimensions(_dimensions, object -> _dimensions) &&
    _pixelFormat == object -> _pixelFormat &&
    _loadAction == object -> _loadAction &&
    _storeAction == object-> _storeAction &&
    _clearColor.red == object -> _clearColor.red &&
    _clearColor.green == object -> _clearColor.green &&
    _clearColor.blue == object -> _clearColor.blue &&
    _clearColor.alpha == object -> _clearColor.alpha;
}

@end

