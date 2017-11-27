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
#import "MTILock.h"
#import "MTIRenderPipelineOutputDescriptor.h"
#import "MTIImagePromiseDebug.h"

@interface MTIRenderPipelineKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic,copy,readonly) NSArray<NSNumber *> *colorAttachmentPixelFormats;

@end

@implementation MTIRenderPipelineKernelConfiguration

- (instancetype)initWithColorAttachmentPixelFormats:(NSArray<NSNumber *> *)colorAttachmentPixelFormats {
    if (self = [super init]) {
        _colorAttachmentPixelFormats = colorAttachmentPixelFormats;
    }
    return self;
}

- (id<NSCopying>)identifier {
    return _colorAttachmentPixelFormats;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (instancetype)configurationWithColorAttachmentPixelFormats:(NSArray<NSNumber *> *)colorAttachmentPixelFormats {
    return [[MTIRenderPipelineKernelConfiguration alloc] initWithColorAttachmentPixelFormats:colorAttachmentPixelFormats];
}

@end

@implementation MTIRenderPipelineKernel

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [self initWithVertexFunctionDescriptor:vertexFunctionDescriptor
                       fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                 vertexDescriptor:nil
                             colorAttachmentCount:1
                            alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
}

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor colorAttachmentCount:(NSUInteger)colorAttachmentCount alphaTypeHandlingRule:(nonnull MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    if (self = [super init]) {
        _vertexFunctionDescriptor = [vertexFunctionDescriptor copy];
        _fragmentFunctionDescriptor = [fragmentFunctionDescriptor copy];
        _vertexDescriptor = [vertexDescriptor copy];
        _colorAttachmentCount = colorAttachmentCount;
        _alphaTypeHandlingRule = alphaTypeHandlingRule;
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(MTIRenderPipelineKernelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSParameterAssert(configuration.colorAttachmentPixelFormats.count == self.colorAttachmentCount);
    
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
    
    for (NSUInteger index = 0; index < self.colorAttachmentCount; index += 1) {
        MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
        colorAttachmentDescriptor.pixelFormat = [configuration.colorAttachmentPixelFormats[index] MTLPixelFormatValue];
        colorAttachmentDescriptor.blendingEnabled = NO;
        renderPipelineDescriptor.colorAttachments[index] = colorAttachmentDescriptor;
    }
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

@end

@interface MTIImageRenderingRecipe : NSObject

@property (nonatomic, copy, readonly) NSArray<MTIRenderCommand *> *renderCommands;

@property (nonatomic,copy,readonly) NSArray<MTIRenderPipelineOutputDescriptor *> *outputDescriptors;

@property (nonatomic, strong, readonly) MTIWeakToStrongObjectsMapTable *resolutionCache;
@property (nonatomic, strong, readonly) id<NSLocking> resolutionCacheLock;

@property (nonatomic, readonly) MTIAlphaType alphaType;

@property (nonatomic, copy, readonly) NSArray<MTIImage *> *dependencies;

@end

@implementation MTIImageRenderingRecipe

- (NSArray<MTIImagePromiseRenderTarget *> *)resolveWithContext:(MTIImageRenderingContext *)renderingContext resolver:(id<MTIImagePromise>)promise error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSError *error = nil;
    NSMutableArray<id<MTIImagePromiseResolution>> *inputResolutions = [NSMutableArray array];
    @MTI_DEFER {
        for (id<MTIImagePromiseResolution> resolution in inputResolutions) {
            [resolution markAsConsumedBy:promise];
        }
    };
    for (MTIImage *image in self.dependencies) {
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
    
    NSMutableArray<NSNumber *> *pixelFormats = [NSMutableArray array];
    for (MTIRenderPipelineOutputDescriptor *outputDescriptor in self.outputDescriptors) {
        MTLPixelFormat pixelFormat = (outputDescriptor.pixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : outputDescriptor.pixelFormat;
        [pixelFormats addObject:@(pixelFormat)];
    }
    
    NSMutableArray<MTIImagePromiseRenderTarget *> *renderTargets = [NSMutableArray array];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    for (NSUInteger index = 0; index < self.outputDescriptors.count; index += 1) {
        MTLPixelFormat pixelFormat = [pixelFormats[index] MTLPixelFormatValue];
        
        MTIRenderPipelineOutputDescriptor *outputDescriptor = self.outputDescriptors[index];
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:outputDescriptor.dimensions.width height:outputDescriptor.dimensions.height mipmapped:NO];
        textureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor]];
        
        renderPassDescriptor.colorAttachments[index].texture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[index].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[index].loadAction = outputDescriptor.loadAction;
        renderPassDescriptor.colorAttachments[index].storeAction = outputDescriptor.storeAction;
        
        [renderTargets addObject:renderTarget];
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

    NSUInteger resolutionIndex = 0;
    
    for (MTIRenderCommand *command in self.renderCommands) {
        MTIRenderPipeline *renderPipeline = [renderingContext.context kernelStateForKernel:command.kernel configuration:[MTIRenderPipelineKernelConfiguration configurationWithColorAttachmentPixelFormats:pixelFormats] error:&error];
        
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        if (command.geometry.bufferLength < 4096) {
            //The setVertexBytes:length:atIndex: method is the best option for binding a very small amount (less than 4 KB) of dynamic buffer data to a vertex function. This method avoids the overhead of creating an intermediary MTLBuffer object. Instead, Metal manages a transient buffer for you.
            [commandEncoder setVertexBytes:command.geometry.bufferBytes length:command.geometry.bufferLength atIndex:0];
        } else {
            id<MTLBuffer> buffer = [renderingContext.context.device newBufferWithBytes:command.geometry.bufferBytes length:command.geometry.bufferLength options:0];
            [commandEncoder setVertexBuffer:buffer offset:0 atIndex:0];
        }
        
        for (NSUInteger index = 0; index < inputResolutions.count; index += 1) {
            [commandEncoder setFragmentTexture:inputResolutions[index + resolutionIndex].texture atIndex:index];
            MTIImage *image = command.images[index];
            NSParameterAssert([command.kernel.alphaTypeHandlingRule canAcceptAlphaType:image.alphaType]);
            id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor];
            [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
        }
        resolutionIndex += command.images.count;
        
        //encode parameters
        if (command.parameters.count > 0) {
            [MTIArgumentsEncoder encodeArguments:renderPipeline.reflection.vertexArguments values:command.parameters functionType:MTLFunctionTypeVertex encoder:commandEncoder error:&error];
            if (error) {
                [commandEncoder endEncoding];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            [MTIArgumentsEncoder encodeArguments:renderPipeline.reflection.fragmentArguments values:command.parameters functionType:MTLFunctionTypeFragment encoder:commandEncoder error:&error];
            if (error) {
                [commandEncoder endEncoding];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        }
        
        [commandEncoder drawPrimitives:command.geometry.primitiveType vertexStart:0 vertexCount:command.geometry.vertexCount];
    }
    
    [commandEncoder endEncoding];
    
    return renderTargets;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                     outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors {
    if (self = [super init]) {
        NSParameterAssert(renderCommands.count > 0);
        _renderCommands = [renderCommands copy];
        _outputDescriptors = outputDescriptors;
        NSMutableArray *dependencies = [NSMutableArray array];
        for (MTIRenderCommand *command in renderCommands) {
            [dependencies addObjectsFromArray:command.images];
        }
        _dependencies = [dependencies copy];
        _alphaType = [renderCommands.lastObject.kernel.alphaTypeHandlingRule outputAlphaTypeForInputImages:renderCommands.lastObject.images];
        _resolutionCache = [[MTIWeakToStrongObjectsMapTable alloc] init];
        _resolutionCacheLock = MTILockCreate();
    }
    return self;
}

@end


@interface MTIImageRenderingPromise: NSObject <MTIImagePromise>

@property (nonatomic, strong, readonly) MTIImageRenderingRecipe *recipe;

@property (nonatomic, readonly) NSUInteger outputIndex;

@end

@implementation MTIImageRenderingPromise

- (NSArray<MTIImage *> *)dependencies {
    return self.recipe.dependencies;
}

- (instancetype)initWithImageRenderingRecipe:(MTIImageRenderingRecipe *)recipe outputIndex:(NSUInteger)index {
    if (self = [super init]) {
        _recipe = recipe;
        _outputIndex = index;
    }
    return self;
}

- (MTITextureDimensions)dimensions {
    return self.recipe.outputDescriptors[self.outputIndex].dimensions;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    if (self.recipe.outputDescriptors.count == 1) {
        return [self.recipe resolveWithContext:renderingContext resolver:self error:error].firstObject;
    } else {
        [self.recipe.resolutionCacheLock lock];
        @MTI_DEFER {
            [self.recipe.resolutionCacheLock unlock];
        };
        NSArray<MTIImagePromiseRenderTarget *> *renderTargets = [self.recipe.resolutionCache objectForKey:renderingContext];
        if (renderTargets) {
            MTIImagePromiseRenderTarget *renderTarget = renderTargets[self.outputIndex];
            if (renderTarget.texture) {
                return renderTarget;
            }
        }
        renderTargets = [self.recipe resolveWithContext:renderingContext resolver:self error:error];
        if (renderTargets) {
            [self.recipe.resolutionCache setObject:renderTargets forKey:renderingContext];
            return renderTargets[self.outputIndex];
        } else {
            return nil;
        }
    }
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (MTIAlphaType)alphaType {
    return _recipe.alphaType;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == self.dependencies.count);
    NSMutableArray *newCommands = [NSMutableArray array];
    NSInteger index = 0;
    for (MTIRenderCommand *command in self.recipe.renderCommands) {
        NSArray *deps = [dependencies subarrayWithRange:NSMakeRange(index, command.images.count)];
        index += command.images.count;
        MTIRenderCommand *newCommand = [[MTIRenderCommand alloc] initWithKernel:command.kernel geometry:command.geometry images:deps parameters:command.parameters];
        [newCommands addObject:newCommand];
    }
    return [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:[[MTIImageRenderingRecipe alloc] initWithRenderCommands:newCommands  outputDescriptors:self.recipe.outputDescriptors] outputIndex:self.outputIndex];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    NSString *content = @"";
    for (MTIRenderCommand *command in self.recipe.renderCommands) {
        content = [content stringByAppendingFormat:@"%@\n%@\n%@\n",
         command.kernel.vertexFunctionDescriptor.name,
         command.kernel.fragmentFunctionDescriptor.name,
         command.parameters];
    }
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:content];
}

@end

@implementation MTIRenderPipelineKernel (ImageCreation)

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:outputTextureDimensions pixelFormat:outputPixelFormat];
    return [self applyToInputImages:images parameters:parameters outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (MTIVertices *)defaultRenderingVertices {
    static MTIVertices *defaultVertices;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect rect = CGRectMake(-1, -1, 2, 2);
        CGFloat l = CGRectGetMinX(rect);
        CGFloat r = CGRectGetMaxX(rect);
        CGFloat t = CGRectGetMinY(rect);
        CGFloat b = CGRectGetMaxY(rect);
        defaultVertices = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
            { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
            { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } },
            { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
            { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } }
        } count:4];
    });
    return defaultVertices;
}

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors {
    return [self imagesByDrawingGeometry:[MTIRenderPipelineKernel defaultRenderingVertices]
                            withTextures:images
                              parameters:parameters
                       outputDescriptors:outputDescriptors];
}

- (NSArray<MTIImage *> *)imagesByDrawingGeometry:(id<MTIGeometry>)geometry
                                    withTextures:(NSArray<MTIImage *> *)images
                                      parameters:(NSDictionary<NSString *,id> *)parameters
                               outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors {
    NSParameterAssert(outputDescriptors.count == self.colorAttachmentCount);
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:self geometry:geometry images:images parameters:parameters];
    MTIImageRenderingRecipe *recipe = [[MTIImageRenderingRecipe alloc] initWithRenderCommands:@[command]
                                                                            outputDescriptors:outputDescriptors];
    NSMutableArray *outputs = [NSMutableArray array];
    for (NSUInteger index = 0; index < outputDescriptors.count; index += 1) {
        MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:recipe outputIndex:index];
        [outputs addObject:[[MTIImage alloc] initWithPromise:promise]];
    }
    return outputs;
}

@end

@implementation MTIRenderCommand (ImageCreation)

+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors {
    MTIImageRenderingRecipe *recipe = [[MTIImageRenderingRecipe alloc] initWithRenderCommands:renderCommands
                                                                            outputDescriptors:outputDescriptors];
    NSMutableArray *outputs = [NSMutableArray array];
    for (NSUInteger index = 0; index < outputDescriptors.count; index += 1) {
        MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:recipe outputIndex:index];
        [outputs addObject:[[MTIImage alloc] initWithPromise:promise]];
    }
    return outputs;
}

@end

#pragma mark - Recipe Merge

#import "MTIColorMatrixFilter.h"
#import "MTIRenderGraphOptimization.h"

@interface MTIImageRenderingRecipe (MTIColorMatrix)

@property (nonatomic, readonly) MTIColorMatrix colorMatrix;

@end

@implementation MTIImageRenderingRecipe (MTIColorMatrix)

- (MTIColorMatrix)colorMatrix {
    MTIColorMatrix colorMatrix = MTIColorMatrixIdentity;
    if (self.renderCommands.count == 1) {
        NSData *data = self.renderCommands.firstObject.parameters[MTIColorMatrixFilterColorMatrixParameterKey];
        if ([data isKindOfClass:[NSData class]] && data.length == sizeof(MTIColorMatrix)) {
            [data getBytes:&colorMatrix length:sizeof(MTIColorMatrix)];
        }
    }
    return colorMatrix;
}

@end

void MTIColorMatrixRenderGraphNodeOptimize(MTIRenderGraphNode *node) {
    if (node.inputs.count == 1 && [node.image.promise isKindOfClass:[MTIImageRenderingPromise class]]) {
        MTIImageRenderingPromise *v = node.image.promise;
        MTIImageRenderingRecipe *recipe = v.recipe;
        MTIRenderGraphNode *lastNode = node.inputs.firstObject;
        MTIImage *lastImage = node.inputs.firstObject.image;
        MTIRenderCommand *command = recipe.renderCommands.firstObject;
        if (recipe.renderCommands.count == 1 && lastNode.uniqueDependentCount == 1 && command.kernel == MTIColorMatrixFilter.kernel && [lastImage.promise isKindOfClass:[MTIImageRenderingPromise class]]) {
            MTIImageRenderingPromise *lastPromise = lastImage.promise;
            MTIColorMatrix colorMatrix = recipe.colorMatrix;
            MTIRenderCommand *lastCommand = lastPromise.recipe.renderCommands.firstObject;
            if (lastPromise.recipe.renderCommands.count == 1 && lastImage.cachePolicy == MTIImageCachePolicyTransient && [lastCommand.geometry isEqual:[MTIRenderPipelineKernel defaultRenderingVertices]] && [lastPromise.recipe.outputDescriptors isEqualToArray:recipe.outputDescriptors] && lastCommand.kernel == MTIColorMatrixFilter.kernel) {
                colorMatrix = MTIColorMatrixConcat(lastPromise.recipe.colorMatrix, colorMatrix);
                MTIImageRenderingRecipe *r = [[MTIImageRenderingRecipe alloc] initWithRenderCommands:@[[[MTIRenderCommand alloc] initWithKernel:command.kernel geometry:command.geometry images:lastPromise.dependencies parameters:@{MTIColorMatrixFilterColorMatrixParameterKey: [NSData dataWithBytes:&colorMatrix length:sizeof(MTIColorMatrix)]}]] outputDescriptors:recipe.outputDescriptors];
                MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:r outputIndex:0];
                node.inputs = lastNode.inputs;
                node.image = [[MTIImage alloc] initWithPromise:promise samplerDescriptor:node.image.samplerDescriptor cachePolicy:node.image.cachePolicy];
            }
        }
    }
}
