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
#import "MTIHasher.h"
#import "MTILock.h"

@interface MTIBlendFilterKernelKey : NSObject <NSCopying>
@property (nonatomic, copy, readonly) MTIBlendMode mode;
@property (nonatomic, readonly) BOOL sourceHasPremultipliedAlpha;
@property (nonatomic, readonly) BOOL backdropHasPremultipliedAlpha;
@property (nonatomic, readonly) BOOL outputsPremultipliedAlpha;
@property (nonatomic, readonly) BOOL outputsOpaqueImage;
@end

@implementation MTIBlendFilterKernelKey

- (instancetype)initWithMode:(MTIBlendMode)mode
           backdropAlphaType:(MTIAlphaType)backdropAlphaType
             sourceAlphaType:(MTIAlphaType)sourceAlphaType
             outputAlphaType:(MTIAlphaType)outputAlphaType {
    if (self = [super init]) {
        _mode = mode;
        _sourceHasPremultipliedAlpha = sourceAlphaType == MTIAlphaTypePremultiplied;
        _backdropHasPremultipliedAlpha = backdropAlphaType == MTIAlphaTypePremultiplied;
        _outputsPremultipliedAlpha = outputAlphaType == MTIAlphaTypePremultiplied;
        _outputsOpaqueImage = outputAlphaType == MTIAlphaTypeAlphaIsOne;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MTIBlendFilterKernelKey class]]) {
        MTIBlendFilterKernelKey *other = object;
        return
        [other->_mode isEqualToString:_mode] &&
        other->_outputsOpaqueImage == _outputsOpaqueImage &&
        other->_outputsPremultipliedAlpha == _outputsPremultipliedAlpha &&
        other->_backdropHasPremultipliedAlpha == _backdropHasPremultipliedAlpha &&
        other->_sourceHasPremultipliedAlpha == _sourceHasPremultipliedAlpha;
    }
    return NO;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _mode.hash);
    MTIHasherCombine(&hasher, (uint64_t)_sourceHasPremultipliedAlpha);
    MTIHasherCombine(&hasher, (uint64_t)_backdropHasPremultipliedAlpha);
    MTIHasherCombine(&hasher, (uint64_t)_outputsPremultipliedAlpha);
    MTIHasherCombine(&hasher, (uint64_t)_outputsOpaqueImage);
    return MTIHasherFinalize(&hasher);
}

@end

@implementation MTIBlendFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernelWithBlendMode:(MTIBlendMode)mode
                               backdropAlphaType:(MTIAlphaType)backdropAlphaType
                                 sourceAlphaType:(MTIAlphaType)sourceAlphaType
                                 outputAlphaType:(MTIAlphaType)outputAlphaType {
    MTIBlendFilterKernelKey *key = [[MTIBlendFilterKernelKey alloc] initWithMode:mode
                                                               backdropAlphaType:backdropAlphaType
                                                                 sourceAlphaType:sourceAlphaType
                                                                 outputAlphaType:outputAlphaType];
    static NSMutableDictionary *kernels;
    static id<NSLocking> kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = MTILockCreate();
    });
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[key];
    if (!kernel) {
        MTLFunctionConstantValues *constantValues = [[MTLFunctionConstantValues alloc] init];
        bool sourceHasPremultipliedAlpha = key.sourceHasPremultipliedAlpha;
        bool backdropHasPremultipliedAlpha = key.backdropHasPremultipliedAlpha;
        bool outputsPremultipliedAlpha = key.outputsPremultipliedAlpha;
        bool outputsOpaqueImage = key.outputsOpaqueImage;
        [constantValues setConstantValue:&sourceHasPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::blend_filter_source_has_premultiplied_alpha"];
        [constantValues setConstantValue:&backdropHasPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::blend_filter_backdrop_has_premultiplied_alpha"];
        [constantValues setConstantValue:&outputsPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::blend_filter_outputs_premultiplied_alpha"];
        [constantValues setConstantValue:&outputsOpaqueImage type:MTLDataTypeBool withName:@"metalpetal::blend_filter_outputs_opaque_image"];
        MTIFunctionDescriptor *fragmentFunctionDescriptor = [[MTIBlendModes functionDescriptorsForBlendMode:mode].fragmentFunctionDescriptorForBlendFilter functionDescriptorWithConstantValues:constantValues];
        MTIAlphaTypeHandlingRule *rule = [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied), @(MTIAlphaTypeNonPremultiplied),@(MTIAlphaTypeAlphaIsOne)] outputAlphaType:outputAlphaType];
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:rule];
        kernels[key] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (instancetype)initWithBlendMode:(MTIBlendMode)mode {
    if (self = [super init]) {
        NSParameterAssert([MTIBlendModes.allModes containsObject:mode]);
        _blendMode = [mode copy];
        _intensity = 1.0;
        _outputAlphaType = MTIAlphaTypeNonPremultiplied;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!_inputBackgroundImage || !_inputImage) {
        return nil;
    }
    MTIRenderPipelineKernel *kernel = [MTIBlendFilter kernelWithBlendMode:_blendMode
                                                        backdropAlphaType:_inputBackgroundImage.alphaType
                                                          sourceAlphaType:_inputImage.alphaType
                                                          outputAlphaType:_outputAlphaType];
    return [kernel applyToInputImages:@[_inputBackgroundImage, _inputImage]
                           parameters:@{@"intensity": @(_intensity)}
              outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputBackgroundImage.size)
                    outputPixelFormat:_outputPixelFormat];
}

@end
