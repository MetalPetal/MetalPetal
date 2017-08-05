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
#import "MTIVector+Private.h"

@interface MTIImageComputeRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIComputePipelineKernel *kernel;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithKernel: (MTIComputePipelineKernel *)kernel
                   inputImages: (NSArray<MTIImage *> *)images
            functionParameters: (NSDictionary<NSString *,id> *)parameters
       outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor;

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
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:computePipeline.state];

    for (NSUInteger index = 0; index < inputResolutions.count; index += 1) {
        [commandEncoder setTexture:inputResolutions[index].texture atIndex:index];
    }
    [commandEncoder setTexture:renderTarget.texture atIndex:inputResolutions.count];
    
    MTIEncodeArgumentsWithEncoder(computePipeline.reflection.arguments, self.functionParameters, commandEncoder, MTLFunctionTypeKernel, &error);

    MTLSize threadGroupCount = MTLSizeMake(8, 8, 1);
    MTLSize threadGroups = MTLSizeMake(self.textureDescriptor.width/threadGroupCount.width,  self.textureDescriptor.height/threadGroupCount.height, 1);
    
    [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupCount];
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

- (instancetype)initWithKernel: (MTIComputePipelineKernel *)kernel inputImages: (NSArray<MTIImage *> *)inputImages functionParameters: (NSDictionary<NSString *,id> *)functionParameters outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _textureDescriptor = [outputTextureDescriptor newMTITextureDescriptor];
        _dimensions = (MTITextureDimensions){outputTextureDescriptor.width, outputTextureDescriptor.height, outputTextureDescriptor.depth};
    }
    return self;
}

@end

@interface MTIComputePipelineKernel()

@property (nonatomic, strong) MTIFunctionDescriptor *computeFunctionDescriptor;

@property (nonatomic, readwrite, assign) MTLPixelFormat pixelFormat;

@end

@implementation MTIComputePipelineKernel

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor pixelFormat:(MTLPixelFormat)pixelFormat {
    if (self = [super init]) {
        _computeFunctionDescriptor = [computeFunctionDescriptor copy];
        _pixelFormat = pixelFormat;
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
    
//    computePipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = NO;
#warning stageInputDescriptor not used
    computePipelineDescriptor.computeFunction = computeFunction;
    return [context computePipelineWithDescriptor:computePipelineDescriptor error:inOutError];
}

- (MTIImage *)applyToInputImages:(NSArray *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    MTIImageComputeRecipe *receipt = [[MTIImageComputeRecipe alloc] initWithKernel:self
                                                                       inputImages:images
                                                                functionParameters:parameters
                                                           outputTextureDescriptor:outputTextureDescriptor];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
