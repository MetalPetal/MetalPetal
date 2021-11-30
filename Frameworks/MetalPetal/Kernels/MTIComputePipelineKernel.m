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
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"
#import "MTIError.h"
#import "MTIPixelFormat.h"
#import "MTIFunctionArgumentsEncoder.h"

@interface MTIComputeFunctionDispatchOptions ()

@property (nonatomic, readonly) MTLSize threads;
@property (nonatomic, readonly) MTLSize threadgroups;
@property (nonatomic, readonly) MTLSize threadsPerThreadgroup;

@property (nonatomic, copy, readonly) void (^generator)(id<MTLComputePipelineState> pipelineState, MTLSize *threads, MTLSize *threadgroups, MTLSize *threadsPerThreadgroup);

@end

@implementation MTIComputeFunctionDispatchOptions

- (instancetype)initWithThreads:(MTLSize)threads threadgroups:(MTLSize)threadgroups threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    if (self = [super init]) {
        _threads = threads;
        _threadgroups = threadgroups;
        _threadsPerThreadgroup = threadsPerThreadgroup;
    }
    return self;
}

- (instancetype)initWithGenerator:(void (^)(id<MTLComputePipelineState> _Nonnull, MTLSize * _Nonnull, MTLSize * _Nonnull, MTLSize * _Nonnull))block {
    if (self = [super init]) {
        _generator = [block copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

__attribute__((objc_subclassing_restricted))
@interface MTIImageComputeRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIComputePipelineKernel *kernel;

@property (nonatomic,copy,readonly) MTIComputeFunctionDispatchOptions *dispatchOptions;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIImageComputeRecipe
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSError *error = nil;
    
    MTIComputePipeline *computePipeline = [renderingContext.context kernelStateForKernel:self.kernel configuration:nil error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;
    
    MTITextureDescriptor *textureDescriptor;
    if (_dimensions.depth > 1) {
        MTLTextureDescriptor *mtlTextureDescriptor;
        mtlTextureDescriptor = [[MTLTextureDescriptor alloc] init];
        mtlTextureDescriptor.textureType = MTLTextureType3D;
        mtlTextureDescriptor.width = _dimensions.width;
        mtlTextureDescriptor.height = _dimensions.height;
        mtlTextureDescriptor.depth = _dimensions.depth;
        mtlTextureDescriptor.pixelFormat = pixelFormat;
        mtlTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
        mtlTextureDescriptor.storageMode = MTLStorageModePrivate;
        textureDescriptor = [mtlTextureDescriptor newMTITextureDescriptor];
    } else {
        textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    }

    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
    
    if (!commandEncoder) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
        }
        return nil;
    }
    
    [commandEncoder setComputePipelineState:computePipeline.state];

    NSUInteger index = 0;
    for (MTIImage *image in self.inputImages) {
        [commandEncoder setTexture:[renderingContext resolvedTextureForImage:image] atIndex:index];
        index += 1;
    }
    [commandEncoder setTexture:renderTarget.texture atIndex:index];
    
    [MTIFunctionArgumentsEncoder encodeArguments:computePipeline.reflection.arguments values:self.functionParameters functionType:MTLFunctionTypeKernel encoder:commandEncoder error:&error];
    
    if (error) {
        [commandEncoder endEncoding];
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }

    NSUInteger w = computePipeline.state.threadExecutionWidth;
    NSUInteger h = computePipeline.state.maxTotalThreadsPerThreadgroup / w;
    MTLSize threadsPerThreadgroup = MTLSizeMake(w, h, 1);
    MTLSize threadgroupsPerGrid = MTLSizeMake((_dimensions.width + w - 1) / w, (_dimensions.height + h - 1) / h, _dimensions.depth);
    MTLSize threadsPerGrid = MTLSizeMake(_dimensions.width,_dimensions.height,_dimensions.depth);
    
    if (_dispatchOptions) {
        if (_dispatchOptions.generator) {
            _dispatchOptions.generator(computePipeline.state, &threadsPerGrid, &threadgroupsPerGrid, &threadsPerThreadgroup);
        } else {
            threadsPerGrid = _dispatchOptions.threads;
            threadgroupsPerGrid = _dispatchOptions.threadgroups;
            threadsPerThreadgroup = _dispatchOptions.threadsPerThreadgroup;
        }
    }
    
    #if TARGET_OS_TV
        [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    #else
        BOOL supportsNonUniformThreadgroupSize = NO;
        
        #if TARGET_OS_IPHONE
            #if TARGET_OS_MACCATALYST
                supportsNonUniformThreadgroupSize = [renderingContext.context.device supportsFamily:MTLGPUFamilyMacCatalyst1];
            #else
                supportsNonUniformThreadgroupSize = [renderingContext.context.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily4_v1];
            #endif
        #else
            supportsNonUniformThreadgroupSize = [renderingContext.context.device supportsFeatureSet:MTLFeatureSet_macOS_GPUFamily1_v3];
        #endif
    
        if (supportsNonUniformThreadgroupSize) {
            [commandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
        } else {
            [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
        }
    #endif

    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (NSArray<MTIImage *> *)dependencies {
    return self.inputImages;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIComputePipelineKernel *)kernel
                   inputImages:(NSArray<MTIImage *> *)inputImages
            functionParameters:(NSDictionary<NSString *,id> *)functionParameters
               dispatchOptions:(nullable MTIComputeFunctionDispatchOptions *)dispatchOptions
       outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
             outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        NSParameterAssert([kernel.alphaTypeHandlingRule _canHandleAlphaTypesInImages:inputImages]);
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _dimensions = outputTextureDimensions;
        _dispatchOptions = [dispatchOptions copy];
        _outputPixelFormat = outputPixelFormat;
        _alphaType = [kernel.alphaTypeHandlingRule outputAlphaTypeForInputImages:inputImages];
    }
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == self.dependencies.count);
    return [[MTIImageComputeRecipe alloc] initWithKernel:_kernel inputImages:dependencies functionParameters:_functionParameters dispatchOptions:_dispatchOptions outputTextureDimensions:_dimensions outputPixelFormat:_outputPixelFormat];
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

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * __autoreleasing *)inOutError {
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
    return [self applyToInputImages:images parameters:parameters dispatchOptions:nil outputTextureDimensions:outputTextureDimensions outputPixelFormat:outputPixelFormat];
}

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters dispatchOptions:(MTIComputeFunctionDispatchOptions *)dispatchOptions outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIImageComputeRecipe *receipt = [[MTIImageComputeRecipe alloc] initWithKernel:self
                                                                       inputImages:images
                                                                functionParameters:parameters
                                                                   dispatchOptions:dispatchOptions
                                                           outputTextureDimensions:outputTextureDimensions
                                                                 outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; %@>",self.class, self, self.computeFunctionDescriptor];
}

@end
