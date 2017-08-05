//
//  MTIMPSGaussianBlurFilter.m
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import "MTIMPSGaussianBlurFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"

@interface MTIMPSGaussianBlurFilter ()

@end

@implementation MTIMPSGaussianBlurFilter

+ (MTIMPSKernel *)kernelWithRadius:(NSInteger)radius {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    [kernelsLock lock];
    MTIMPSKernel *kernel = kernels[@(radius)];
    if (!kernel) {
        //ceil(sqrt(-log(0.01)*2)*sigma) ~ ceil(3.7*sigma)
        float sigma = radius;
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            return [[MPSImageGaussianBlur alloc] initWithDevice:device sigma:sigma];
        }];
        kernels[@(radius)] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (ceil(self.radius) <= 0) {
        return self.inputImage;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [[self.class kernelWithRadius:ceil(self.radius)] applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDescriptor:outputTextureDescriptor];
}

@end
