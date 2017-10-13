//
//  MTIRenderPipelineKernel.m
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import "MTIRenderPipelineKernel.h"
#import "MTIContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImagePromise.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTIImage+Promise.h"
#import "MTIDefer.h"
#import "MTIWeakToStrongObjectsMapTable.h"

@interface MTIImageRenderingRecipe : NSObject

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIRenderPipelineKernel *kernel;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@property (nonatomic,copy,readonly) NSArray<MTIRenderPipelineOutputDescriptor *> *outputDescriptors;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@property (nonatomic, strong) MTIWeakToStrongObjectsMapTable *resolutionMap;

@end

@implementation MTIImageRenderingRecipe

- (MTIVertices *)verticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4];
}

- (NSArray<MTIImagePromiseRenderTarget *> *)resolveWithContext:(MTIImageRenderingContext *)renderingContext byPromise:(id<MTIImagePromise>)promise error:(NSError * _Nullable __autoreleasing *)inOutError {
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
    
    @MTI_DEFER {
        for (id<MTIImagePromiseResolution> resolution in inputResolutions) {
            [resolution markAsConsumedBy:promise];
        }
    };
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;

    MTIRenderPipeline *renderPipeline = [renderingContext.context kernelStateForKernel:self.kernel pixelFormat:pixelFormat error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    NSMutableArray<MTIImagePromiseRenderTarget *> *renderTargets = [NSMutableArray array];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

    for (NSUInteger index = 0; index < self.outputDescriptors.count; index += 1) {
        MTIRenderPipelineOutputDescriptor *outputDescriptor = self.outputDescriptors[index];
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:outputDescriptor.dimensions.width height:outputDescriptor.dimensions.height mipmapped:NO];
        textureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor]];
        
        renderPassDescriptor.colorAttachments[index].texture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[index].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[index].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[index].storeAction = MTLStoreActionStore;
        
        [renderTargets addObject:renderTarget];
    }
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    
    if (vertices.count * sizeof(MTIVertex) < 4096) {
        //The setVertexBytes:length:atIndex: method is the best option for binding a very small amount (less than 4 KB) of dynamic buffer data to a vertex function. This method avoids the overhead of creating an intermediary MTLBuffer object. Instead, Metal manages a transient buffer for you.
        [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
    } else {
        id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
        [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    }
    
    for (NSUInteger index = 0; index < inputResolutions.count; index += 1) {
        [commandEncoder setFragmentTexture:inputResolutions[index].texture atIndex:index];
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.inputImages[index].samplerDescriptor];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
    }
    
    //encode parameters
    if (self.functionParameters.count > 0) {
        [MTIArgumentsEncoder encodeArguments:renderPipeline.reflection.vertexArguments values:self.functionParameters functionType:MTLFunctionTypeVertex encoder:commandEncoder error:&error];
        if (error) {
            [commandEncoder endEncoding];
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        [MTIArgumentsEncoder encodeArguments:renderPipeline.reflection.fragmentArguments values:self.functionParameters functionType:MTLFunctionTypeFragment encoder:commandEncoder error:&error];
        if (error) {
            [commandEncoder endEncoding];
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    }
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    return renderTargets;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIRenderPipelineKernel *)kernel
                   inputImages:(NSArray<MTIImage *> *)inputImages
            functionParameters:(NSDictionary<NSString *,id> *)functionParameters
             outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors
             outputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _outputDescriptors = outputDescriptors;
        _outputPixelFormat = pixelFormat;
        _resolutionMap = [[MTIWeakToStrongObjectsMapTable alloc] init];
    }
    return self;
}

@end

#import "MTILock.h"

@interface MTIImageRenderingRecipeView: NSObject <MTIImagePromise>

@property (nonatomic, strong, readonly) MTIImageRenderingRecipe *recipe;

@property (nonatomic, readonly) NSUInteger outputIndex;

@property (nonatomic, strong, readonly) id<NSLocking> lock;

@end

@implementation MTIImageRenderingRecipeView

- (NSArray<MTIImage *> *)dependencies {
    return self.recipe.inputImages;
}

- (instancetype)initWithImageRenderingRecipe:(MTIImageRenderingRecipe *)recipe outputIndex:(NSUInteger)index {
    if (self = [super init]) {
        _recipe = recipe;
        _outputIndex = index;
        _lock = MTICreateLock();
    }
    return self;
}

- (MTITextureDimensions)dimensions {
    return self.recipe.outputDescriptors[self.outputIndex].dimensions;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    [self.lock lock];
    NSArray<MTIImagePromiseRenderTarget *> *renderTargets = [self.recipe.resolutionMap objectForKey:renderingContext];
    [self.lock unlock];
    if (renderTargets) {
        MTIImagePromiseRenderTarget *renderTarget = renderTargets[self.outputIndex];
        if (renderTarget.texture) {
            return renderTarget;
        }
    }
    renderTargets = [self.recipe resolveWithContext:renderingContext byPromise:self error:error];
    if (renderTargets) {
        [self.lock lock];
        [self.recipe.resolutionMap setObject:renderTargets forKey:renderingContext];
        [self.lock unlock];
        return renderTargets[self.outputIndex];
    } else {
        return nil;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end


@implementation MTIRenderPipelineOutputDescriptor

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions {
    if (self = [super init]) {
        _dimensions = dimensions;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end


@interface MTIRenderPipelineKernel ()

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *vertexFunctionDescriptor;
@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptor;
@property (nonatomic,copy,readonly) MTLVertexDescriptor *vertexDescriptor;
@property (nonatomic,readonly) NSUInteger colorAttachmentCount;

@end

@implementation MTIRenderPipelineKernel

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [self initWithVertexFunctionDescriptor:vertexFunctionDescriptor
                       fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                 vertexDescriptor:nil
                             colorAttachmentCount:1];
}

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor colorAttachmentCount:(NSUInteger)colorAttachmentCount {
    if (self = [super init]) {
        _vertexFunctionDescriptor = [vertexFunctionDescriptor copy];
        _fragmentFunctionDescriptor = [fragmentFunctionDescriptor copy];
        _vertexDescriptor = [vertexDescriptor copy];
        _colorAttachmentCount = colorAttachmentCount;
    }
    return self;
}

- (MTIRenderPipeline *)newKernelStateWithContext:(MTIContext *)context pixelFormat:(MTLPixelFormat)pixelFormat error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor;
    
    NSError *error;
    id<MTLFunction> vertextFunction = [context functionWithDescriptor:self.vertexFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:self.fragmentFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    renderPipelineDescriptor.vertexFunction = vertextFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.pixelFormat = pixelFormat;
    colorAttachmentDescriptor.blendingEnabled = NO;
    
    for (NSUInteger index = 0; index < self.colorAttachmentCount; index += 1) {
        renderPipelineDescriptor.colorAttachments[index] = colorAttachmentDescriptor;
    }
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:outputTextureDimensions];
    return [self applyToInputImages:images parameters:parameters outputDescriptors:@[outputDescriptor] outputPixelFormat:outputPixelFormat].firstObject;
}

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIImageRenderingRecipe *receipt = [[MTIImageRenderingRecipe alloc] initWithKernel:self
                                                                           inputImages:images
                                                                    functionParameters:parameters
                                                                     outputDescriptors:outputDescriptors
                                                                     outputPixelFormat:outputPixelFormat];
    NSMutableArray *outputs = [NSMutableArray array];
    for (NSUInteger index = 0; index < outputDescriptors.count; index += 1) {
        MTIImageRenderingRecipeView *promise = [[MTIImageRenderingRecipeView alloc] initWithImageRenderingRecipe:receipt outputIndex:index];
        [outputs addObject:[[MTIImage alloc] initWithPromise:promise]];
    }
    return outputs;
}

@end
