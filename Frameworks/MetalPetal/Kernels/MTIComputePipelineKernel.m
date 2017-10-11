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

@interface MTIImageComputeRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIComputePipelineKernel *kernel;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@end

@implementation MTIImageComputeRecipe
@synthesize dimensions = _dimensions;

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSError *error = nil;
    NSMutableArray<id<MTIImagePromiseResolution>> *inputResolutions = [NSMutableArray array];
    for (MTIImage *image in self.inputImages) {
        id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        NSAssert(resolution != nil, @"");
        [inputResolutions addObject:resolution];
    }
    
    MTIComputePipeline *computePipeline = [renderingContext.context kernelStateForKernel:self.kernel error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:renderingContext.context.workingPixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;

    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor]];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:computePipeline.state];

    for (NSUInteger index = 0; index < inputResolutions.count; index += 1) {
        [commandEncoder setTexture:inputResolutions[index].texture atIndex:index];
    }
    [commandEncoder setTexture:renderTarget.texture atIndex:inputResolutions.count];
    
    [MTIArgumentsEncoder encodeArguments:computePipeline.reflection.arguments values:self.functionParameters functionType:MTLFunctionTypeKernel encoder:commandEncoder error:&error];
    
    if (error) {
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
        [commandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    } else {
        [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    }
    
    [commandEncoder endEncoding];
    
    for (id<MTIImagePromiseResolution> resolution in inputResolutions) {
        [resolution markAsConsumedBy:self];
    }
    
    return renderTarget;
}

- (NSArray<MTIImage *> *)dependencies {
    return self.inputImages;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel: (MTIComputePipelineKernel *)kernel inputImages: (NSArray<MTIImage *> *)inputImages functionParameters: (NSDictionary<NSString *,id> *)functionParameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _dimensions = outputTextureDimensions;
    }
    return self;
}

@end

@interface MTIComputePipelineKernel()

@property (nonatomic, copy, readonly) MTIFunctionDescriptor *computeFunctionDescriptor;

@end

@implementation MTIComputePipelineKernel

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor {
    if (self = [super init]) {
        _computeFunctionDescriptor = [computeFunctionDescriptor copy];
    }
    return self;
}

- (nullable MTIComputePipeline *)newKernelStateWithContext:(MTIContext *)context error:(NSError * _Nullable __autoreleasing *)inOutError {
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

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions {
    MTIImageComputeRecipe *receipt = [[MTIImageComputeRecipe alloc] initWithKernel:self
                                                                       inputImages:images
                                                                functionParameters:parameters
                                                           outputTextureDimensions:outputTextureDimensions];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
