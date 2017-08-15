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
#import <CommonCrypto/CommonCrypto.h>
#import <zlib.h>


@implementation ConvolutionInputSets

- (instancetype)initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float *)matrixPoint
{
    if( self = [super init] ){
        self.width = width;
        self.height = height;
        long matrixSize = self.width*self.height*sizeof(float);
        self.matrixPoint = malloc(matrixSize);
        memcpy(self.matrixPoint, matrixPoint, matrixSize);
    }
    return self;
}
- (void)dealloc{
    if( self.matrixPoint )
        free(self.matrixPoint);
}
- (id)copyWithZone:(NSZone *)zone
{
//    return self;
    ConvolutionInputSets *aCopy = [[ConvolutionInputSets allocWithZone:zone] initWithWidth:self.width Height:self.height Weights:self.matrixPoint];
    return aCopy;
}

- (BOOL)isEqual:(id)object
{
    if( [object isKindOfClass:self.class] ){
        ConvolutionInputSets* cis = (ConvolutionInputSets*)object;
        long matrixSize = self.width*self.height*sizeof(float);
        if( cis.width == self.width && cis.height == self.height && memcmp(cis.matrixPoint, self.matrixPoint, matrixSize)==0 )
            return YES;
    }
    return NO;
}
- (NSUInteger)hash
{
    NSUInteger hash = 0;
    long matrixSize = self.width*self.height*sizeof(float);
#ifdef CRC_HASH_CONVOLUTION
    uLong crc = crc32(0L, Z_NULL, 0);
    hash = crc32(crc, self.matrixPoint, mlen);
#else
    hash = [[[NSData alloc] initWithBytes:self.matrixPoint length:matrixSize] hash];
#endif
    return hash;
}

@end

@implementation MTIMPSImageConvolution

- (instancetype) initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float* _Nonnull) matrixPoint
{
    if( self = [super init] ){
        self.inputSets = [[ConvolutionInputSets alloc] initWithWidth:width Height:height Weights:matrixPoint];
    }
    return self;
}

+ (MTIMPSKernel *)kernelWithInputSets:(ConvolutionInputSets*) inputSets {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    [kernelsLock lock];
    MTIMPSKernel *kernel = kernels[inputSets];
    if (!kernel) {
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            return [[MPSImageConvolution alloc] initWithDevice:device kernelWidth:inputSets.width kernelHeight:inputSets.height weights:inputSets.matrixPoint];
        }];
        kernels[inputSets] = kernel;
    }
    [kernelsLock unlock];
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (self.inputSets.width <= 0 || self.inputSets.height <= 0 || self.inputSets.matrixPoint == nil ) {
        return self.inputImage;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB
                                                                                                       width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [[self.class kernelWithInputSets:self.inputSets] applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDescriptor:outputTextureDescriptor];
    
    return nil;
}

@end
