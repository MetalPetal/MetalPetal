//
//  MTIColorInvertFilter.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIColorInvertFilter.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"

@implementation MTIColorInvertFilter

- (instancetype)init {
    return [self initWithVertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_vertex"]
                       fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_color_invert"]];
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    return [self applyWithInputImages:@[self.inputImage] parameters:@[] outputTextureDescriptor:outputTextureDescriptor];
}

@end
