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
    if (self = [super init]) {
        _dimensions = dimensions;
        _pixelFormat = pixelFormat;
        _loadAction = loadAction;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MTIRenderPipelineOutputDescriptor class]]) {
        return [self isEqualToOutputDescriptor:object];
    }
    return NO;
}

- (BOOL)isEqualToOutputDescriptor:(MTIRenderPipelineOutputDescriptor *)object {
    return MTITextureDimensionsEqualToTextureDimensions(_dimensions, object.dimensions) && _pixelFormat == object.pixelFormat && _loadAction == object.loadAction;
}

@end

