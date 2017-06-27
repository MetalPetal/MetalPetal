//
//  MTIImagePromise.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIImagePromise.h"

@implementation MTIImageRenderingReceiptBuilder

@end

@implementation MTIImageRenderingReceipt

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithBuilder:(MTIImageRenderingReceiptBuilder *)builder {
    if (self = [super init]) {
        _inputImages = builder.inputImages;
        _vertexFunctionDescriptor = builder.vertexFunctionDescriptor;
        _fragmentFunctionDescriptor = builder.fragmentFunctionDescriptor;
        _fragmentFunctionParameters = builder.fragmentFunctionParameters;
        _outputTextureDescriptor = builder.outputTextureDescriptor;
    }
    return self;
}

@end
