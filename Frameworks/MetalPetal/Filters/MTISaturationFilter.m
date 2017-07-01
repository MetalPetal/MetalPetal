//
//  MTISaturationFilter.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTISaturationFilter.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"

@implementation MTISaturationFilter

- (instancetype)init {
    return [self initWithVertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                       fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"saturationAdjust"]];
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    return [self applyWithInputImages:@[self.inputImage] parameters:@{@"saturation": @(self.saturation)} outputTextureDescriptor:outputTextureDescriptor];
}

@end
