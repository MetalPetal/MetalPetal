//
//  MTIComputePipelineKernel.m
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIComputePipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIContext.h"
#import "MTIImage.h"
#import "MTIImagePromise.h"
#import "MTIImage+Promise.h"
#import "MTITextureDescriptor.h"
#import "MTIImageRenderingContext.h"
#import "MTIComputePipeline.h"
#import "MTIVector.h"
#import "MTIDefer.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"

@interface MTIImageComputeRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIComputePipelineKernel *kernel;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIImageComputeRecipe
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSError *error = nil;
    
    NSUInteger inputResolutionsCount = self.inputImages.count;
    id<MTIImagePromiseResolution> inputResolutions[inputResolutionsCount];
    memset(inputResolutions, 0, sizeof inputResolutions);
    const id<MTIImagePromiseResolution> * inputResolutionsRef = inputResolutions;
    @MTI_DEFER {
        for (NSUInteger index = 0; index < inputResolutionsCount; index+=1) {
            [inputResolutionsRef[index] markAsConsumedBy:self];
        }
    };
    for (NSUInteger index = 0; index < inputResolutionsCount; index += 1) {
        MTIImage *image = self.inputImages[index];
        NSParameterAssert([self.kernel.alphaTypeHandlingRule canAcceptAlphaType:image.alphaType]);
        id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        NSAssert(resolution != nil, @"");
        inputResolutions[index] = resolution;
    }
    
    MTIComputePipeline *computePipeline = [renderingContext.context kernelStateForKernel:self.kernel configuration:nil error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;

    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:computePipeline.state];

    for (NSUInteger index = 0; index < inputResolutionsCount; index += 1) {
        [commandEncoder setTexture:inputResolutions[index].texture atIndex:index];
    }
    [commandEncoder setTexture:renderTarget.texture atIndex:inputResolutionsCount];
    
    [MTIArgumentsEncoder encodeArguments:computePipeline.reflection.arguments values:self.functionParameters functionType:MTLFunctionTypeKernel encoder:commandEncoder error:&error];
    
    if (error) {
        [commandEncoder endEncoding];
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }

    NSUInteger w = computePipeline.state.threadExecutionWidth;
    NSUInteger h = computePipeline.state.maxTotalThreadsPerThreadgroup / w;
    MTLSize threadsPerGrid = MTLSizeMake(_dimensions.width,_dimensions.height,1);
    MTLSize threadsPerThreadgroup = MTLSizeMake(w, h, 1);
    MTLSize threadgroupsPerGrid = MTLSizeMake((_dimensions.width + w - 1) / w, (_dimensions.height + h - 1) / h, 1);
    
    if (@available(iOS 11.0, *)) {
        if ([renderingContext.context.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily4_v1]) {
            [commandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
        } else {
            [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
        }
    } else {
        [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    }
    
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (NSArray<MTIImage *> *)dependencies {
    return self.inputImages;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel: (MTIComputePipelineKernel *)kernel inputImages: (NSArray<MTIImage *> *)inputImages functionParameters: (NSDictionary<NSString *,id> *)functionParameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _dimensions = outputTextureDimensions;
        _outputPixelFormat = outputPixelFormat;
        _alphaType = [kernel.alphaTypeHandlingRule outputAlphaTypeForInputImages:inputImages];
    }
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == self.dependencies.count);
    return [[MTIImageComputeRecipe alloc] initWithKernel:self.kernel inputImages:dependencies functionParameters:self.functionParameters outputTextureDimensions:self.dimensions outputPixelFormat:self.outputPixelFormat];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    NSString *content = [NSString stringWithFormat:@"%@\n%@\n",self.kernel.computeFunctionDescriptor.name, self.functionParameters];
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:content];
}

@end

@implementation MTIComputePipelineKernel

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor {
    return [self initWithComputeFunctionDescriptor:computeFunctionDescriptor alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
}

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor alphaTypeHandlingRule:(MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    if (self = [super init]) {
        _computeFunctionDescriptor = [computeFunctionDescriptor copy];
        _alphaTypeHandlingRule = alphaTypeHandlingRule;
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTLComputePipelineDescriptor *computePipelineDescriptor = [[MTLComputePipelineDescriptor alloc] init];
    NSError *error;
    id<MTLFunction> computeFunction = [context functionWithDescriptor:self.computeFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    computePipelineDescriptor.computeFunction = computeFunction;
    return [context computePipelineWithDescriptor:computePipelineDescriptor error:inOutError];
}

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIImageComputeRecipe *receipt = [[MTIImageComputeRecipe alloc] initWithKernel:self
                                                                       inputImages:images
                                                                functionParameters:parameters
                                                           outputTextureDimensions:outputTextureDimensions
                                                                 outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; %@>",self.class, self, self.computeFunctionDescriptor];
}

@end
