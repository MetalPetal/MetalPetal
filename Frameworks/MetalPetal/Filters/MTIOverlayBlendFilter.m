//
//  MTIOverlayBlendFilter.m
//  Pods
//
//  Created by YuAo on 30/07/2017.
//
//

#import "MTIOverlayBlendFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"

@implementation MTIOverlayBlendFilter

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //Hard Light is equivalent to Overlay, but with the bottom and top images swapped.
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"hardLightBlend"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputBackgroundImage || !self.inputForegroundImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputForegroundImage,self.inputBackgroundImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputBackgroundImage.size)];
}

+ (NSSet *)inputParameterKeys {
    return [NSSet set];
}

@end
