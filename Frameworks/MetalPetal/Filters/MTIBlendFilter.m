//
//  MTIBlendFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 12/10/2017.
//

#import "MTIBlendFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIRenderPipelineKernel.h"

@interface MTIBlendFilter ()

@property (nonatomic,strong,readonly) MTIRenderPipelineKernel *kernel;

@end

@implementation MTIBlendFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernelWithBlendMode:(MTIBlendMode)mode {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[mode];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[MTIBlendModes functionDescriptorsForBlendMode:mode].fragmentFunctionDescriptorForBlendFilter];
        kernels[mode] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (instancetype)initWithBlendMode:(MTIBlendMode)mode {
    if (self = [super init]) {
        NSParameterAssert([MTIBlendModes.allModes containsObject:mode]);
        _blendMode = [mode copy];
        _kernel = [MTIBlendFilter kernelWithBlendMode:mode];
        _intensity = 1.0;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!_inputBackgroundImage || !_inputImage) {
        return nil;
    }
    return [self.kernel applyToInputImages:@[_inputBackgroundImage, _inputImage]
                                parameters:@{@"intensity": @(_intensity)}
                   outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputBackgroundImage.size)
                         outputPixelFormat:_outputPixelFormat];
}

@end
