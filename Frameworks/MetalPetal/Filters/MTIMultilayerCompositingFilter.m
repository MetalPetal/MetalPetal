//
//  MTIMultilayerCompositingFilter.m
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIMultilayerCompositingFilter.h"
#import "MTIImage.h"

@implementation MTIMultilayerCompositingFilter

+ (MTIMultilayerCompositeKernel *)kernel {
    static MTIMultilayerCompositeKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIMultilayerCompositeKernel alloc] initWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB];
    });
    return kernel;
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

- (MTIImage *)outputImage {
    if (!self.inputBackgroundImage) {
        return nil;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.class.kernel.pixelFormat width:self.inputBackgroundImage.size.width height:self.inputBackgroundImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [self.class.kernel applyToBackgroundImage:self.inputBackgroundImage layers:self.layers outputTextureDescriptor:outputTextureDescriptor];
}

@end
