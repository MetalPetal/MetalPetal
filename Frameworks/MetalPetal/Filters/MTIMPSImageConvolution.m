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

@interface MTIConvolutionInputSets : NSObject<NSCopying>
@property (nonatomic, assign)               NSUInteger       kernelWidth;
@property (nonatomic, assign)               NSUInteger       kernelHeight;
@property (nonatomic, assign, nullable)     float*           kernelWeights;

- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float* __nonnull)kernelWeights NS_DESIGNATED_INITIALIZER;
@end

@implementation MTIConvolutionInputSets

- (instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float* __nonnull)kernelWeights
{
    if( self = [super init] ){
        self.kernelWidth = kernelWidth;
        self.kernelHeight = kernelHeight;
        long kernelWeightsSize = self.kernelWidth*self.kernelWidth*sizeof(float);
        self.kernelWeights = malloc(kernelWeightsSize);
        memcpy(self.kernelWeights, kernelWeights, kernelWeightsSize);
    }
    return self;
}
- (void)dealloc{
    if( self.kernelWeights ){
        free(self.kernelWeights);
    }
}
- (id)copyWithZone:(NSZone *)zone
{
    MTIConvolutionInputSets *deepCopy = [[MTIConvolutionInputSets allocWithZone:zone] initWithKernelWidth:self.kernelWidth kernelHeight:self.kernelHeight weights:self.kernelWeights];
    return deepCopy;
}

- (BOOL)isEqual:(id)object
{
    if( [object isKindOfClass:self.class] ){
        MTIConvolutionInputSets* mcis = (MTIConvolutionInputSets*)object;
        long kernelWeightsSize = self.kernelWidth*self.kernelHeight*sizeof(float);
        if( mcis.kernelWidth == self.kernelWidth && mcis.kernelHeight == self.kernelHeight && memcmp(mcis.kernelWeights, self.kernelWeights, kernelWeightsSize)==0 )
            return YES;
    }
    return NO;
}
- (NSUInteger)hash
{
    NSUInteger hash = 0;
    long kernelWeightsSize = self.kernelWidth*self.kernelHeight*sizeof(float);
#ifdef CRC_HASH_CONVOLUTION
    uLong crc = crc32(0L, Z_NULL, 0);
    hash = crc32(crc, self.kernelWeights, mlen);
#else
    hash = [[[NSData alloc] initWithBytes:self.kernelWeights length:kernelWeightsSize] hash];
#endif
    return hash;
}

@end

@implementation MTIMPSImageConvolution

- (instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float* __nonnull)kernelWeights
{
    if( self = [super init] ){
        _inputSets = [[MTIConvolutionInputSets alloc] initWithKernelWidth:kernelWidth kernelHeight:kernelHeight weights:kernelWeights];
    }
    return self;
}

+ (MTIMPSKernel *)kernelWithInputSets:(MTIConvolutionInputSets*) inputSets {
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
            return [[MPSImageConvolution alloc] initWithDevice:device kernelWidth:inputSets.kernelWidth kernelHeight:inputSets.kernelHeight weights:inputSets.kernelWeights];
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
    if (self.inputSets.kernelWidth <= 0 || self.inputSets.kernelHeight <= 0 || self.inputSets.kernelWeights == nil ) {
        return self.inputImage;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB
                                                                                                       width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [[self.class kernelWithInputSets:self.inputSets] applyToInputImages:@[self.inputImage]
                    parameters:@{NSStringFromSelector(@selector(bias)): @(self.bias) } outputTextureDescriptor:outputTextureDescriptor];
    
    return nil;
}

@end
