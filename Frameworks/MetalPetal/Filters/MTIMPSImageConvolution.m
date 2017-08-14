//
//  MTIMPSImageConvolution.m
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import "MTIMPSImageConvolution.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"

@implementation MTIMPSImageConvolution

- (instancetype) initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float* _Nonnull) matrixPoint
{
    if( self = [super init] ){
        self.width = width;
        self.height = height;
        long copysize = self.width*self.height*sizeof(float);
        self.matrixConvolution = malloc(copysize);
        memcpy(self.matrixConvolution, matrixPoint, copysize);
    }
    return self;
}
- (void)dealloc{
    if( self.matrixConvolution )
        free(self.matrixConvolution);
}

+ (MTIMPSKernel *)kernelWithWidth:(NSInteger)nWidth Height:(NSInteger)nHeight Weights:(const float* _Nonnull) matrix {
//    static NSMutableDictionary *kernels;
//    static NSLock *kernelsLock;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kernels = [NSMutableDictionary dictionary];
//        kernelsLock = [[NSLock alloc] init];
//    });
//    
//    [kernelsLock lock];
//    MTIMPSKernel *kernel = kernels[@(radius)];
    MTIMPSKernel *kernel = nil;
    if (!kernel) {
        //ceil(sqrt(-log(0.01)*2)*sigma) ~ ceil(3.7*sigma)
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            return [[MPSImageConvolution alloc] initWithDevice:device kernelWidth:nWidth kernelHeight:nHeight weights:matrix];
        }];
//        kernels[@(radius)] = kernel;
    }
//    [kernelsLock unlock];
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (self.width <= 0 || self.height <= 0 || self.matrixConvolution == nil ) {
        return self.inputImage;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB
                                                                                                       width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [[self.class kernelWithWidth:self.width Height:self.height Weights:self.matrixConvolution] applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDescriptor:outputTextureDescriptor];
    
    return nil;
}

@end
