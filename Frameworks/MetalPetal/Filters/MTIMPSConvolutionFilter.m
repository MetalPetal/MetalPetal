//
//  MTIMPSImageConvolution.m
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import "MTIMPSConvolutionFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"
#import "MTIHasher.h"

@interface MTIMPSImageConvolutionSettings : NSObject <NSCopying>

@property (nonatomic,readonly) NSUInteger kernelWidth;
@property (nonatomic,readonly) NSUInteger kernelHeight;

@property (nonatomic,copy,readonly) NSData *weights;

@end

@implementation MTIMPSImageConvolutionSettings

- (instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float *)kernelWeights {
    if (self = [super init]) {
        NSParameterAssert(kernelWidth);
        NSParameterAssert(kernelHeight);
        NSParameterAssert(kernelWeights);
        _kernelWidth = kernelWidth;
        _kernelHeight = kernelHeight;
        _weights = [NSData dataWithBytes:kernelWeights length:kernelWidth * kernelHeight * sizeof(float)];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIMPSImageConvolutionSettings class]]) {
        MTIMPSImageConvolutionSettings *settings = object;
        return [_weights isEqualToData:settings -> _weights] && _kernelWidth == settings -> _kernelWidth && _kernelHeight == settings -> _kernelHeight;
    }
    return NO;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _weights.hash);
    MTIHasherCombine(&hasher, _kernelWidth);
    MTIHasherCombine(&hasher, _kernelHeight);
    return MTIHasherFinalize(&hasher);
}

@end

@interface MTIMPSConvolutionFilter ()

@property (nonatomic, copy, readonly) MTIMPSImageConvolutionSettings *settings;

@property (nonatomic, strong, readonly) MTIMPSKernel *kernel;

@end

@implementation MTIMPSConvolutionFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float *)kernelWeights {
    if (self = [super init]) {
        _settings = [[MTIMPSImageConvolutionSettings alloc] initWithKernelWidth:kernelWidth kernelHeight:kernelHeight weights:kernelWeights];
        _kernel = [MTIMPSConvolutionFilter kernelWithSettings:_settings];
        _bias = 0;
    }
    return self;
}

+ (MTIMPSKernel *)kernelWithSettings:(MTIMPSImageConvolutionSettings *)settings {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    [kernelsLock lock];
    MTIMPSKernel *kernel = kernels[settings];
    if (!kernel) {
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            return [[MPSImageConvolution alloc] initWithDevice:device kernelWidth:settings.kernelWidth kernelHeight:settings.kernelHeight weights:settings.weights.bytes];
        }];
        kernels[settings] = kernel;
    }
    [kernelsLock unlock];
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [self.kernel applyToInputImages:@[self.inputImage]
                                parameters:@{NSStringFromSelector(@selector(bias)): @(self.bias)}
                   outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                         outputPixelFormat:_outputPixelFormat];
}

@end
