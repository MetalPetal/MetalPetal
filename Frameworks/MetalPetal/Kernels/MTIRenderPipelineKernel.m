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
#import "MTIRenderPassOutputDescriptor.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"
#import "MTIHasher.h"
#import "MTIError.h"
#import "MTIPixelFormat.h"
#import "MTIFunctionArgumentsEncoder.h"

NSUInteger const MTIRenderPipelineMaximumColorAttachmentCount = 8;

@interface MTIRenderPipelineKernelConfiguration () {
    MTLPixelFormat _pixelFormats[MTIRenderPipelineMaximumColorAttachmentCount];
}
@end

@implementation MTIRenderPipelineKernelConfiguration

- (instancetype)initWithColorAttachmentPixelFormats:(MTLPixelFormat [])colorAttachmentPixelFormats count:(NSUInteger)count {
    return [self initWithColorAttachmentPixelFormats:colorAttachmentPixelFormats count:count depthAttachmentPixelFormat:MTLPixelFormatInvalid stencilAttachmentPixelFormat:MTLPixelFormatInvalid rasterSampleCount:1];
}

- (instancetype)initWithColorAttachmentPixelFormats:(MTLPixelFormat [])colorAttachmentPixelFormats count:(NSUInteger)count depthAttachmentPixelFormat:(MTLPixelFormat)depthAttachmentPixelFormat stencilAttachmentPixelFormat:(MTLPixelFormat)stencilAttachmentPixelFormat rasterSampleCount:(NSUInteger)rasterSampleCount {
    if (self = [super init]) {
        NSParameterAssert(count <= MTIRenderPipelineMaximumColorAttachmentCount);
        count = MIN(count, MTIRenderPipelineMaximumColorAttachmentCount);
        for (NSUInteger index = 0; index < count; index += 1) {
            _pixelFormats[index] = colorAttachmentPixelFormats[index];
        }
        _colorAttachmentCount = count;
        _depthAttachmentPixelFormat = depthAttachmentPixelFormat;
        _stencilAttachmentPixelFormat = stencilAttachmentPixelFormat;
        _rasterSampleCount = rasterSampleCount;
    }
    return self;
}

- (instancetype)initWithColorAttachmentPixelFormat:(MTLPixelFormat)colorAttachmentPixelFormat {
    MTLPixelFormat formats[] = {colorAttachmentPixelFormat};
    return [self initWithColorAttachmentPixelFormats:formats count:1 depthAttachmentPixelFormat:MTLPixelFormatInvalid stencilAttachmentPixelFormat:MTLPixelFormatInvalid rasterSampleCount:1];
}

- (const MTLPixelFormat *)colorAttachmentPixelFormats {
    return _pixelFormats;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    for (NSUInteger index = 0; index < _colorAttachmentCount; index += 1) {
        MTIHasherCombine(&hasher, _pixelFormats[index]);
    }
    MTIHasherCombine(&hasher, _depthAttachmentPixelFormat);
    MTIHasherCombine(&hasher, _stencilAttachmentPixelFormat);
    MTIHasherCombine(&hasher, _rasterSampleCount);
    return MTIHasherFinalize(&hasher);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    MTIRenderPipelineKernelConfiguration *obj = object;
    if ([obj isKindOfClass:MTIRenderPipelineKernelConfiguration.class] &&
        obj -> _colorAttachmentCount == _colorAttachmentCount &&
        obj -> _rasterSampleCount == _rasterSampleCount) {
        for (NSUInteger index = 0; index < _colorAttachmentCount; index += 1) {
            if ((obj -> _pixelFormats)[index] != _pixelFormats[index]) {
                return NO;
            }
        }
        if (_depthAttachmentPixelFormat != obj -> _depthAttachmentPixelFormat ||
            _stencilAttachmentPixelFormat != obj -> _stencilAttachmentPixelFormat) {
            return NO;
        }
        return YES;
    } else {
        return NO;
    }
}

- (id<NSCopying>)identifier {
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (instancetype)configurationWithColorAttachmentPixelFormats:(MTLPixelFormat[])colorAttachmentPixelFormats count:(NSUInteger)count rasterSampleCount:(NSUInteger)rasterSampleCount {
    return [[MTIRenderPipelineKernelConfiguration alloc] initWithColorAttachmentPixelFormats:colorAttachmentPixelFormats count:count depthAttachmentPixelFormat:MTLPixelFormatInvalid stencilAttachmentPixelFormat:MTLPixelFormatInvalid rasterSampleCount:rasterSampleCount];
}

@end

@implementation MTIRenderPipelineKernel

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    NSParameterAssert(vertexFunctionDescriptor);
    NSParameterAssert(fragmentFunctionDescriptor);
    return [self initWithVertexFunctionDescriptor:vertexFunctionDescriptor
                       fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                 vertexDescriptor:nil
                             colorAttachmentCount:1
                            alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
}

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor colorAttachmentCount:(NSUInteger)colorAttachmentCount alphaTypeHandlingRule:(nonnull MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    if (self = [super init]) {
        NSParameterAssert(vertexFunctionDescriptor);
        NSParameterAssert(fragmentFunctionDescriptor);
        _vertexFunctionDescriptor = [vertexFunctionDescriptor copy];
        _fragmentFunctionDescriptor = [fragmentFunctionDescriptor copy];
        _vertexDescriptor = [vertexDescriptor copy];
        _colorAttachmentCount = colorAttachmentCount;
        _alphaTypeHandlingRule = alphaTypeHandlingRule;
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(MTIRenderPipelineKernelConfiguration *)configuration error:(NSError * __autoreleasing *)inOutError {
    NSParameterAssert(configuration.colorAttachmentCount == self.colorAttachmentCount);
    
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
        colorAttachmentDescriptor.pixelFormat = configuration.colorAttachmentPixelFormats[index];
        colorAttachmentDescriptor.blendingEnabled = NO;
        renderPipelineDescriptor.colorAttachments[index] = colorAttachmentDescriptor;
    }
    renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthAttachmentPixelFormat;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = configuration.stencilAttachmentPixelFormat;
    
    renderPipelineDescriptor.rasterSampleCount = configuration.rasterSampleCount;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; vertexFunctionDescriptor = %@; fragmentFunctionDescriptor = %@>",self.class, self, self.vertexFunctionDescriptor, self.fragmentFunctionDescriptor];
}

@end

__attribute__((objc_subclassing_restricted))
@interface MTIImageRenderingRecipe : NSObject

@property (nonatomic, copy, readonly) NSArray<MTIRenderCommand *> *renderCommands;

@property (nonatomic,copy,readonly) NSArray<MTIRenderPassOutputDescriptor *> *outputDescriptors;

@property (nonatomic, strong, readonly) MTIWeakToStrongObjectsMapTable *resolutionCache;
@property (nonatomic, strong, readonly) id<NSLocking> resolutionCacheLock;

@property (nonatomic, readonly) MTIAlphaType alphaType;

@property (nonatomic, copy, readonly) NSArray<MTIImage *> *dependencies;

@property (nonatomic, readonly) NSUInteger rasterSampleCount;

@end

@implementation MTIImageRenderingRecipe

- (NSArray<MTIImagePromiseRenderTarget *> *)resolveWithContext:(MTIImageRenderingContext *)renderingContext resolver:(id<MTIImagePromise>)promise error:(NSError * __autoreleasing *)inOutError {
    NSError *error = nil;

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    NSUInteger outputCount = self.outputDescriptors.count;
    MTLPixelFormat pixelFormats[outputCount];
    MTIImagePromiseRenderTarget *renderTargets[outputCount];
    for (NSUInteger index = 0; index < outputCount; index += 1) {
        MTIRenderPassOutputDescriptor *outputDescriptor = self.outputDescriptors[index];
        
        MTLPixelFormat pixelFormat = (outputDescriptor.pixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : outputDescriptor.pixelFormat;
        pixelFormats[index] = pixelFormat;
        
        MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:outputDescriptor.dimensions.width height:outputDescriptor.dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
        MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        if (_rasterSampleCount > 1) {
            if (renderingContext.context.isMemorylessTextureSupported) {
                MTLTextureDescriptor *tempTextureDescriptor = [textureDescriptor newMTLTextureDescriptor];
                tempTextureDescriptor.textureType = MTLTextureType2DMultisample;
                tempTextureDescriptor.usage = MTLTextureUsageRenderTarget;
                if (@available(macCatalyst 14.0, macOS 11.0, *)) {
                    tempTextureDescriptor.storageMode = MTLStorageModeMemoryless;
                } else {
                    NSAssert(NO, @"");
                }
                tempTextureDescriptor.sampleCount = _rasterSampleCount;
                id<MTLTexture> msaaTexture = [renderingContext.context.device newTextureWithDescriptor:tempTextureDescriptor];
                if (!msaaTexture) {
                    if (inOutError) {
                        *inOutError = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
                    }
                    return nil;
                }
                renderPassDescriptor.colorAttachments[index].texture = msaaTexture;
                renderPassDescriptor.colorAttachments[index].clearColor = outputDescriptor.clearColor;
                if (outputDescriptor.loadAction == MTLLoadActionLoad) {
                    NSAssert(NO, @"Cannot use `MTLLoadActionLoad` for memoryless render target. Fallback to `MTLLoadActionClear`.");
                    renderPassDescriptor.colorAttachments[index].loadAction = MTLLoadActionClear;
                } else {
                    renderPassDescriptor.colorAttachments[index].loadAction = outputDescriptor.loadAction;
                }
                renderPassDescriptor.colorAttachments[index].storeAction = MTLStoreActionMultisampleResolve;
                renderPassDescriptor.colorAttachments[index].resolveTexture = renderTarget.texture;
            } else {
                MTLTextureDescriptor *tempTextureDescriptor = [textureDescriptor newMTLTextureDescriptor];
                tempTextureDescriptor.textureType = MTLTextureType2DMultisample;
                tempTextureDescriptor.usage = MTLTextureUsageRenderTarget;
                tempTextureDescriptor.sampleCount = _rasterSampleCount;
                MTIImagePromiseRenderTarget *msaaTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:[tempTextureDescriptor newMTITextureDescriptor] error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                renderPassDescriptor.colorAttachments[index].texture = msaaTarget.texture;
                renderPassDescriptor.colorAttachments[index].clearColor = outputDescriptor.clearColor;
                renderPassDescriptor.colorAttachments[index].loadAction = outputDescriptor.loadAction;
                renderPassDescriptor.colorAttachments[index].storeAction = MTLStoreActionMultisampleResolve;
                renderPassDescriptor.colorAttachments[index].resolveTexture = renderTarget.texture;
                [msaaTarget releaseTexture];
            }
        } else {
            renderPassDescriptor.colorAttachments[index].texture = renderTarget.texture;
            renderPassDescriptor.colorAttachments[index].clearColor = outputDescriptor.clearColor;
            renderPassDescriptor.colorAttachments[index].loadAction = outputDescriptor.loadAction;
            renderPassDescriptor.colorAttachments[index].storeAction = outputDescriptor.storeAction;
        }
        
        renderTargets[index] = renderTarget;
    }
    
    id<MTLRenderCommandEncoder> commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    if (!commandEncoder) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
        }
        return nil;
    }
    
    for (MTIRenderCommand *command in self.renderCommands) {
        MTIRenderPipeline *renderPipeline = [renderingContext.context kernelStateForKernel:command.kernel configuration:[MTIRenderPipelineKernelConfiguration configurationWithColorAttachmentPixelFormats:pixelFormats count:outputCount rasterSampleCount:_rasterSampleCount] error:&error];
        
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            
            [commandEncoder endEncoding];
            return nil;
        }
        
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        for (MTLArgument *argument in renderPipeline.reflection.vertexArguments) {
            if (argument.type == MTLArgumentTypeTexture) {
                NSUInteger index = argument.index;
                if (index < command.images.count) {
                    id<MTLTexture> texture = [renderingContext resolvedTextureForImage:command.images[index]];
                    id<MTLSamplerState> samplerState = [renderingContext resolvedSamplerStateForImage:command.images[index]];
                    [commandEncoder setVertexTexture:texture atIndex:index];
                    [commandEncoder setVertexSamplerState:samplerState atIndex:index];
                } else {
                    NSAssert(NO, @"Failed to set vertex textures.");
                    if (inOutError) {
                        NSDictionary *userInfo = @{
                            @"kernel": command.kernel,
                            @"stage": @"vertex",
                            @"argument": argument.name
                        };
                        *inOutError = MTIErrorCreate(MTIErrorTextureBindingFailed, userInfo);
                    }
                    [commandEncoder endEncoding];
                    return nil;
                }
            }
        }
        
        for (MTLArgument *argument in renderPipeline.reflection.fragmentArguments) {
            if (argument.type == MTLArgumentTypeTexture) {
                NSUInteger index = argument.index;
                if (index < command.images.count) {
                    id<MTLTexture> texture = [renderingContext resolvedTextureForImage:command.images[index]];
                    id<MTLSamplerState> samplerState = [renderingContext resolvedSamplerStateForImage:command.images[index]];
                    [commandEncoder setFragmentTexture:texture atIndex:index];
                    [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
                } else {
                    NSAssert(NO, @"Failed to set fragment textures.");
                    if (inOutError) {
                        NSDictionary *userInfo = @{
                            @"kernel": command.kernel,
                            @"stage": @"fragment",
                            @"argument": argument.name
                        };
                        *inOutError = MTIErrorCreate(MTIErrorTextureBindingFailed, userInfo);
                    }
                    [commandEncoder endEncoding];
                    return nil;
                }
            }
        }
                
        //encode parameters
        if (command.parameters.count > 0) {
            [MTIFunctionArgumentsEncoder encodeArguments:renderPipeline.reflection.vertexArguments values:command.parameters functionType:MTLFunctionTypeVertex encoder:commandEncoder error:&error];
            if (error) {
                NSAssert(NO, @"Cannot encode vertex arguments: %@", error);
                if (inOutError) {
                    *inOutError = error;
                }
                [commandEncoder endEncoding];
                return nil;
            }
            
            [MTIFunctionArgumentsEncoder encodeArguments:renderPipeline.reflection.fragmentArguments values:command.parameters functionType:MTLFunctionTypeFragment encoder:commandEncoder error:&error];
            if (error) {
                NSAssert(NO, @"Cannot encode fragment arguments: %@", error);
                if (inOutError) {
                    *inOutError = error;
                }
                [commandEncoder endEncoding];
                return nil;
            }
        }
        
        [command.geometry encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    }
    
    [commandEncoder endEncoding];
    
    return [NSArray arrayWithObjects:renderTargets count:self.outputDescriptors.count];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                     rasterSampleCount:(NSUInteger)rasterSampleCount
                     outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors {
    if (self = [super init]) {
        NSParameterAssert(renderCommands.count > 0);
        NSParameterAssert(rasterSampleCount >= 1);
        NSParameterAssert(outputDescriptors.count > 0);
        _renderCommands = [renderCommands copy];
        _outputDescriptors = [outputDescriptors copy];
        _rasterSampleCount = rasterSampleCount;
        if (renderCommands.count == 0) {
            _dependencies = @[];
        } else if (renderCommands.count == 1) {
            _dependencies = renderCommands.firstObject.images;
        } else {
            NSMutableArray<MTIImage *> *dependencies = [NSMutableArray array];
            for (MTIRenderCommand *command in renderCommands) {
                [dependencies addObjectsFromArray:command.images];
            }
            _dependencies = [dependencies copy];
        }
        _alphaType = [renderCommands.lastObject.kernel.alphaTypeHandlingRule outputAlphaTypeForInputImages:renderCommands.lastObject.images];
        if (outputDescriptors.count > 1) {
            _resolutionCache = [[MTIWeakToStrongObjectsMapTable alloc] init];
            _resolutionCacheLock = MTILockCreate();
        }
    }
    return self;
}

@end

__attribute__((objc_subclassing_restricted))
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
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
    return [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:[[MTIImageRenderingRecipe alloc] initWithRenderCommands:newCommands rasterSampleCount:_recipe.rasterSampleCount outputDescriptors:_recipe.outputDescriptors] outputIndex:_outputIndex];
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
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:outputTextureDimensions pixelFormat:outputPixelFormat];
    return [self applyToInputImages:images parameters:parameters outputDescriptors:@[outputDescriptor]].firstObject;
}

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors {
    NSParameterAssert(outputDescriptors.count == _colorAttachmentCount);
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:self geometry:MTIVertices.fullViewportSquareVertices images:images parameters:parameters];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:outputDescriptors];
}

@end

#import "MTIFilter.h"

@implementation MTIRenderPipelineKernel (PassthroughKernel)

+ (MTIRenderPipelineKernel *)passthroughRenderPipelineKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName] vertexDescriptor:nil colorAttachmentCount:1 alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
    });
    return kernel;
}

@end

@implementation MTIRenderCommand (ImageCreation)

+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors {
    return [self imagesByPerformingRenderCommands:renderCommands rasterSampleCount:1 outputDescriptors:outputDescriptors];
}

+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                                        rasterSampleCount:(NSUInteger)rasterSampleCount
                                        outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors {
    MTIImageRenderingRecipe *recipe = [[MTIImageRenderingRecipe alloc] initWithRenderCommands:renderCommands
                                                                            rasterSampleCount:rasterSampleCount
                                                                            outputDescriptors:outputDescriptors];
    if (outputDescriptors.count == 0) {
        return @[];
    } else if (outputDescriptors.count == 1) {
        MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:recipe outputIndex:0];
        return @[[[MTIImage alloc] initWithPromise:promise]];
    } else {
        NSMutableArray *outputs = [NSMutableArray array];
        for (NSUInteger index = 0; index < outputDescriptors.count; index += 1) {
            MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:recipe outputIndex:index];
            [outputs addObject:[[MTIImage alloc] initWithPromise:promise]];
        }
        return outputs;
    }
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
            if (lastPromise.recipe.renderCommands.count == 1 && lastImage.cachePolicy == MTIImageCachePolicyTransient && [lastCommand.geometry isEqual:MTIVertices.fullViewportSquareVertices] && [lastPromise.recipe.outputDescriptors isEqualToArray:recipe.outputDescriptors] && lastCommand.kernel == MTIColorMatrixFilter.kernel) {
                colorMatrix = MTIColorMatrixConcat(lastPromise.recipe.colorMatrix, colorMatrix);
                MTIImageRenderingRecipe *r = [[MTIImageRenderingRecipe alloc] initWithRenderCommands:@[[[MTIRenderCommand alloc] initWithKernel:command.kernel geometry:command.geometry images:lastPromise.dependencies parameters:@{MTIColorMatrixFilterColorMatrixParameterKey: [NSData dataWithBytes:&colorMatrix length:sizeof(MTIColorMatrix)]}]] rasterSampleCount:MAX(recipe.rasterSampleCount,lastPromise.recipe.rasterSampleCount) outputDescriptors:recipe.outputDescriptors];
                MTIImageRenderingPromise *promise = [[MTIImageRenderingPromise alloc] initWithImageRenderingRecipe:r outputIndex:0];
                node.inputs = lastNode.inputs;
                node.image = [[MTIImage alloc] initWithPromise:promise samplerDescriptor:node.image.samplerDescriptor cachePolicy:node.image.cachePolicy];
            }
        }
    }
}
