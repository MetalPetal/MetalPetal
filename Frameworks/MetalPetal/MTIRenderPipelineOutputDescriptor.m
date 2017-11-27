//
//  MTIRenderPipelineOutputDescriptor.m
//  Pods
//
//  Created by YuAo on 18/11/2017.
//

#import "MTIRenderPipelineOutputDescriptor.h"

@implementation MTIRenderPipelineOutputDescriptor

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat {
    return [self initWithDimensions:dimensions pixelFormat:pixelFormat loadAction:MTLLoadActionDontCare];
}

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction {
    return [self initWithDimensions:dimensions pixelFormat:pixelFormat loadAction:loadAction storeAction:MTLStoreActionStore];
}

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction storeAction:(MTLStoreAction)storeAction {
    if (self = [super init]) {
        _dimensions = dimensions;
        _pixelFormat = pixelFormat;
        _loadAction = loadAction;
        _storeAction = storeAction;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return _dimensions.width ^ _dimensions.height ^ _dimensions.depth ^ _pixelFormat ^ _loadAction ^ _storeAction;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MTIRenderPipelineOutputDescriptor class]]) {
        return [self isEqualToOutputDescriptor:object];
    }
    return NO;
}

- (BOOL)isEqualToOutputDescriptor:(MTIRenderPipelineOutputDescriptor *)object {
    return MTITextureDimensionsEqualToTextureDimensions(_dimensions, object.dimensions) && _pixelFormat == object.pixelFormat && _loadAction == object.loadAction && _storeAction == object.storeAction;
}

@end

