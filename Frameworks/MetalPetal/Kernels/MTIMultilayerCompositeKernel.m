//
//  MTIMultilayerRenderPipelineKernel.m
//  MetalPetal
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIMultilayerCompositeKernel.h"
#import "MTIContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImagePromise.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTIImage+Promise.h"
#import "MTIFilter.h"
#import "MTIDefer.h"
#import "MTITransform.h"
#import "MTILayer.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"
#import "MTIError.h"

#define MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS (TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR)

@interface MTIMultilayerCompositeKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIMultilayerCompositeKernelConfiguration
@synthesize identifier = _identifier;

- (instancetype)initWithOutputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (self = [super init]) {
        _outputPixelFormat = pixelFormat;
        _identifier = @(pixelFormat);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (instancetype)configurationWithOutputPixelFormat:(MTLPixelFormat)pixelFormat {
    return [[MTIMultilayerCompositeKernelConfiguration alloc] initWithOutputPixelFormat:pixelFormat];
}

@end

@interface MTIMultilayerCompositeKernelState: NSObject

@property (nonatomic,copy,readonly) NSDictionary<MTIBlendMode, MTIRenderPipeline *> *pipelines;

@property (nonatomic,copy,readonly) MTIRenderPipeline *passthroughRenderPipeline;

@property (nonatomic,copy,readonly) MTIRenderPipeline *unpremultiplyAlphaRenderPipeline;

@property (nonatomic,copy,readonly) MTIRenderPipeline *passthroughToColorAttachmentOneRenderPipeline;

@property (nonatomic,copy,readonly) MTIRenderPipeline *unpremultiplyAlphaToColorAttachmentOneRenderPipeline;

@end

@implementation MTIMultilayerCompositeKernelState

+ (MTIRenderPipeline *)renderPipelineWithFragmentFunctionName:(NSString *)fragmentFunctionName colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor context:(MTIContext *)context error:(NSError * __autoreleasing *)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    NSError *error;
    id<MTLFunction> vertextFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    renderPipelineDescriptor.vertexFunction = vertextFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0] = colorAttachmentDescriptor;
    #if MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS
    // on macOS colorAttachments 1 is not used.
    renderPipelineDescriptor.colorAttachments[1] = colorAttachmentDescriptor;
    #endif
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (instancetype)initWithContext:(MTIContext *)context colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor error:(NSError * __autoreleasing *)inOutError {
    if (self = [super init]) {
        NSError *error;
        
        _passthroughRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:MTIFilterPassthroughFragmentFunctionName colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _unpremultiplyAlphaRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:MTIFilterUnpremultiplyAlphaFragmentFunctionName colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _passthroughToColorAttachmentOneRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"passthroughToColorAttachmentOne" colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _unpremultiplyAlphaToColorAttachmentOneRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"unpremultiplyAlphaToColorAttachmentOne" colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        NSMutableDictionary *pipelines = [NSMutableDictionary dictionary];
        for (MTIBlendMode mode in MTIBlendModes.allModes) {
            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            
            NSError *error = nil;
            id<MTLFunction> vertextFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"multilayerCompositeVertexShader"] error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[MTIBlendModes functionDescriptorsForBlendMode:mode].fragmentFunctionDescriptorForMultilayerCompositingFilter error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            renderPipelineDescriptor.vertexFunction = vertextFunction;
            renderPipelineDescriptor.fragmentFunction = fragmentFunction;
            
            renderPipelineDescriptor.colorAttachments[0] = colorAttachmentDescriptor;
            #if MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS
            // on macOS colorAttachments 1 is not used.
            renderPipelineDescriptor.colorAttachments[1] = colorAttachmentDescriptor;
            #endif
            renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
            renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
            
            MTIRenderPipeline *pipeline = [context renderPipelineWithDescriptor:renderPipelineDescriptor error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            pipelines[mode] = pipeline;
        }
        _pipelines = [pipelines copy];
    }
    return self;
}

- (MTIRenderPipeline *)pipelineWithBlendMode:(MTIBlendMode)blendMode {
    return self.pipelines[blendMode];
}

@end

@interface MTIMultilayerCompositingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTIImage *backgroundImage;

@property (nonatomic,strong,readonly) MTIMultilayerCompositeKernel *kernel;

@property (nonatomic,copy,readonly) NSArray<MTILayer *> *layers;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIMultilayerCompositingRecipe
@synthesize dimensions = _dimensions;
@synthesize dependencies = _dependencies;

- (MTIVertices *)verticesForRect:(CGRect)rect contentRegion:(CGRect)contentRegion flipOptions:(MTILayerFlipOptions)flipOptions {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    CGFloat contentL = CGRectGetMinX(contentRegion);
    CGFloat contentR = CGRectGetMaxX(contentRegion);
    CGFloat contentT = CGRectGetMaxY(contentRegion);
    CGFloat contentB = CGRectGetMinY(contentRegion);
    
    if (flipOptions & MTILayerFlipOptionsFlipVertically) {
        CGFloat temp = contentT;
        contentT = contentB;
        contentB = temp;
    }
    if (flipOptions & MTILayerFlipOptionsFlipHorizontally) {
        CGFloat temp = contentL;
        contentL = contentR;
        contentR = temp;
    }
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { contentL, contentT } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { contentR, contentT } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { contentL, contentB } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { contentR, contentB } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
}

#if MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS

// iOS
- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    
    NSError *error = nil;
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;

    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel configuration:[MTIMultilayerCompositeKernelConfiguration configurationWithOutputPixelFormat:pixelFormat] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    //Set up color attachment 1 for compositing mask
    MTLTextureDescriptor *tempTextureDescriptor = [textureDescriptor newMTLTextureDescriptor];
    tempTextureDescriptor.storageMode = MTLStorageModeMemoryless;
    id<MTLTexture> compositingMaskTexture = [renderingContext.context.device newTextureWithDescriptor:tempTextureDescriptor];
    if (!compositingMaskTexture) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    renderPassDescriptor.colorAttachments[1].texture = compositingMaskTexture;
    renderPassDescriptor.colorAttachments[1].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[1].storeAction = MTLStoreActionDontCare;
    
    id<MTLSamplerState> backgroundSamplerState = [renderingContext.context samplerStateWithDescriptor:self.backgroundImage.samplerDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLSamplerState> compositingMaskSamplerStates[self.layers.count];
    id<MTLSamplerState> layerSamplerStates[self.layers.count];
    
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTILayer *layer = self.layers[index];
        {
            if (layer.compositingMask) {
                id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:layer.compositingMask.content.samplerDescriptor error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                compositingMaskSamplerStates[index] = samplerState;
            }
        }
        {
            id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:layer.content.samplerDescriptor error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            layerSamplerStates[index] = samplerState;
        }
    }
    
    //render background
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2) contentRegion:CGRectMake(0, 0, 1, 1) flipOptions:MTILayerFlipOptionsDonotFlip];
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    if (!commandEncoder) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
        }
        return nil;
    }
    
    NSParameterAssert(self.backgroundImage.alphaType != MTIAlphaTypeUnknown);
    
    MTIRenderPipeline *renderPipeline;
    if (self.backgroundImage.alphaType == MTIAlphaTypePremultiplied) {
        renderPipeline = [kernelState unpremultiplyAlphaRenderPipeline];
    } else {
        renderPipeline = [kernelState passthroughRenderPipeline];
    }
    
    [commandEncoder setRenderPipelineState:renderPipeline.state];

    [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:self.backgroundImage] atIndex:0];
    [commandEncoder setFragmentSamplerState:backgroundSamplerState atIndex:0];
    
    [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTILayer *layer = self.layers[index];
        
        if (layer.compositingMask) {
            NSParameterAssert(layer.compositingMask.content.alphaType != MTIAlphaTypeUnknown);
            
            MTIRenderPipeline *renderPipeline;
            if (layer.compositingMask.content.alphaType == MTIAlphaTypePremultiplied) {
                renderPipeline = [kernelState unpremultiplyAlphaToColorAttachmentOneRenderPipeline];
            } else {
                renderPipeline = [kernelState passthroughToColorAttachmentOneRenderPipeline];
            }
            [commandEncoder setRenderPipelineState:renderPipeline.state];
            
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.compositingMask.content] atIndex:0];
            [commandEncoder setFragmentSamplerState:compositingMaskSamplerStates[index] atIndex:0];
            
            [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
        }
        
        NSParameterAssert(layer.content.alphaType != MTIAlphaTypeUnknown);
        
        CGSize layerPixelSize = [layer sizeInPixelForBackgroundSize:self.backgroundImage.size];
        CGPoint layerPixelPosition = [layer positionInPixelForBackgroundSize:self.backgroundImage.size];
        
        MTIVertices *vertices = [self verticesForRect:CGRectMake(-layerPixelSize.width/2.0, -layerPixelSize.height/2.0, layerPixelSize.width, layerPixelSize.height)
                                        contentRegion:CGRectMake(layer.contentRegion.origin.x/layer.content.size.width, layer.contentRegion.origin.y/layer.content.size.height, layer.contentRegion.size.width/layer.content.size.width, layer.contentRegion.size.height/layer.content.size.height)
                                          flipOptions:layer.contentFlipOptions];
        
        MTIRenderPipeline *renderPipeline = [kernelState pipelineWithBlendMode:layer.blendMode];
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        //transformMatrix
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, layerPixelPosition.x - self.backgroundImage.size.width/2.0, -(layerPixelPosition.y - self.backgroundImage.size.height/2.0), 0);
        transform = CATransform3DRotate(transform, -layer.rotation, 0, 0, 1);
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(transform);
        [commandEncoder setVertexBytes:&transformMatrix length:sizeof(transformMatrix) atIndex:1];
        
        //orthographicMatrix
        simd_float4x4 orthographicMatrix = MTIMakeOrthographicMatrix(-self.backgroundImage.size.width/2.0, self.backgroundImage.size.width/2.0, -self.backgroundImage.size.height/2.0, self.backgroundImage.size.height/2.0, -1, 1);
        [commandEncoder setVertexBytes:&orthographicMatrix length:sizeof(orthographicMatrix) atIndex:2];
        
        [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.content] atIndex:0];
        [commandEncoder setFragmentSamplerState:layerSamplerStates[index] atIndex:0];
        
        //parameters
        MTIMultilayerCompositingLayerShadingParameters parameters;
        parameters.opacity = layer.opacity;
        parameters.contentHasPremultipliedAlpha = (layer.content.alphaType == MTIAlphaTypePremultiplied);
        parameters.hasCompositingMask = !(layer.compositingMask == nil);
        parameters.compositingMaskComponent = (int)layer.compositingMask.component;
        parameters.usesOneMinusMaskValue = (layer.compositingMask.mode == MTIMaskModeOneMinusMaskValue);
        [commandEncoder setFragmentBytes:&parameters length:sizeof(parameters) atIndex:0];
        
        [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    return renderTarget;
}

#else

// macOS || Simulator
- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    
    NSError *error = nil;
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;
    
    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel configuration:[MTIMultilayerCompositeKernelConfiguration configurationWithOutputPixelFormat:pixelFormat] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLSamplerState> backgroundSamplerState = [renderingContext.context samplerStateWithDescriptor:self.backgroundImage.samplerDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLSamplerState> compositingMaskSamplerStates[self.layers.count];
    id<MTLSamplerState> layerSamplerStates[self.layers.count];
    
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTILayer *layer = self.layers[index];
        {
            if (layer.compositingMask) {
                id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:layer.compositingMask.content.samplerDescriptor error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                compositingMaskSamplerStates[index] = samplerState;
            }
        }
        {
            id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:layer.content.samplerDescriptor error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            layerSamplerStates[index] = samplerState;
        }
    }
    
    //render background
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2) contentRegion:CGRectMake(0, 0, 1, 1) flipOptions:MTILayerFlipOptionsDonotFlip];
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    if (!commandEncoder) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
        }
        return nil;
    }
    
    NSParameterAssert(self.backgroundImage.alphaType != MTIAlphaTypeUnknown);
    
    MTIRenderPipeline *renderPipeline;
    if (self.backgroundImage.alphaType == MTIAlphaTypePremultiplied) {
        renderPipeline = [kernelState unpremultiplyAlphaRenderPipeline];
    } else {
        renderPipeline = [kernelState passthroughRenderPipeline];
    }
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:self.backgroundImage] atIndex:0];
    [commandEncoder setFragmentSamplerState:backgroundSamplerState atIndex:0];
    [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        
        #if TARGET_OS_SIMULATOR
        //we are on simulator, no texture barrier available, end current commend encoder then create a new one.
        [commandEncoder endEncoding];
        commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        #else
        //we are on macOS, use textureBarrier.
        [commandEncoder textureBarrier];
        #endif
        
        MTILayer *layer = self.layers[index];
        
        if (layer.compositingMask) {
            NSParameterAssert(layer.compositingMask.content.alphaType != MTIAlphaTypeUnknown);
            //Configuration not supported on macOS currently.
            NSParameterAssert(!(layer.compositingMask.content.alphaType == MTIAlphaTypePremultiplied && layer.compositingMask.component != MTIColorComponentAlpha));
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.compositingMask.content] atIndex:2];
        }
        
        NSParameterAssert(layer.content.alphaType != MTIAlphaTypeUnknown);
        
        CGSize layerPixelSize = [layer sizeInPixelForBackgroundSize:self.backgroundImage.size];
        CGPoint layerPixelPosition = [layer positionInPixelForBackgroundSize:self.backgroundImage.size];
        
        MTIVertices *vertices = [self verticesForRect:CGRectMake(-layerPixelSize.width/2.0, -layerPixelSize.height/2.0, layerPixelSize.width, layerPixelSize.height)
                                        contentRegion:CGRectMake(layer.contentRegion.origin.x/layer.content.size.width, layer.contentRegion.origin.y/layer.content.size.height, layer.contentRegion.size.width/layer.content.size.width, layer.contentRegion.size.height/layer.content.size.height)
                                          flipOptions:layer.contentFlipOptions];
        
        MTIRenderPipeline *renderPipeline = [kernelState pipelineWithBlendMode:layer.blendMode];
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        //transformMatrix
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, layerPixelPosition.x - self.backgroundImage.size.width/2.0, -(layerPixelPosition.y - self.backgroundImage.size.height/2.0), 0);
        transform = CATransform3DRotate(transform, -layer.rotation, 0, 0, 1);
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(transform);
        [commandEncoder setVertexBytes:&transformMatrix length:sizeof(transformMatrix) atIndex:1];
        
        //orthographicMatrix
        simd_float4x4 orthographicMatrix = MTIMakeOrthographicMatrix(-self.backgroundImage.size.width/2.0, self.backgroundImage.size.width/2.0, -self.backgroundImage.size.height/2.0, self.backgroundImage.size.height/2.0, -1, 1);
        [commandEncoder setVertexBytes:&orthographicMatrix length:sizeof(orthographicMatrix) atIndex:2];
        
        [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.content] atIndex:0];
        [commandEncoder setFragmentSamplerState:layerSamplerStates[index] atIndex:0];
        
        [commandEncoder setFragmentTexture:renderTarget.texture atIndex:1];
        
        //parameters
        MTIMultilayerCompositingLayerShadingParameters parameters;
        parameters.opacity = layer.opacity;
        parameters.contentHasPremultipliedAlpha = (layer.content.alphaType == MTIAlphaTypePremultiplied);
        parameters.hasCompositingMask = !(layer.compositingMask == nil);
        parameters.compositingMaskComponent = (int)layer.compositingMask.component;
        parameters.usesOneMinusMaskValue = (layer.compositingMask.mode == MTIMaskModeOneMinusMaskValue);
        [commandEncoder setFragmentBytes:&parameters length:sizeof(parameters) atIndex:0];
        
        simd_float2 viewportSize = simd_make_float2(self.backgroundImage.size.width, self.backgroundImage.size.height);
        [commandEncoder setFragmentBytes:&viewportSize length:sizeof(simd_float2) atIndex:1];

        [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    return renderTarget;
}

#endif

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (MTIAlphaType)alphaType {
    return MTIAlphaTypeNonPremultiplied;
}

- (instancetype)initWithKernel:(MTIMultilayerCompositeKernel *)kernel
               backgroundImage:(MTIImage *)backgroundImage
                        layers:(NSArray<MTILayer *> *)layers
       outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
             outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        _backgroundImage = backgroundImage;
        _kernel = kernel;
        _layers = layers;
        _dimensions = outputTextureDimensions;
        _outputPixelFormat = outputPixelFormat;
        NSMutableArray *dependencies = [NSMutableArray arrayWithCapacity:layers.count + 1];
        [dependencies addObject:backgroundImage];
        for (MTILayer *layer in layers) {
            [dependencies addObject:layer.content];
            if (layer.compositingMask) {
                [dependencies addObject:layer.compositingMask.content];
            }
        }
        _dependencies = [dependencies copy];
    }
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSAssert(dependencies.count == self.dependencies.count, @"");
    NSInteger pointer = 0;
    MTIImage *backgroundImage = dependencies[pointer];
    pointer += 1;
    NSMutableArray *newLayers = [NSMutableArray arrayWithCapacity:self.layers.count];
    for (MTILayer *layer in self.layers) {
        MTIImage *newContent = dependencies[pointer];
        pointer += 1;
        MTIMask *compositingMask = layer.compositingMask;
        MTIMask *newCompositingMask = nil;
        if (compositingMask) {
            MTIImage *newCompositingMaskContent = dependencies[pointer];
            pointer += 1;
            newCompositingMask = [[MTIMask alloc] initWithContent:newCompositingMaskContent component:compositingMask.component mode:compositingMask.mode];
        }
        MTILayer *newLayer = [[MTILayer alloc] initWithContent:newContent contentRegion:layer.contentRegion contentFlipOptions:layer.contentFlipOptions compositingMask:newCompositingMask layoutUnit:layer.layoutUnit position:layer.position size:layer.size rotation:layer.rotation opacity:layer.opacity blendMode:layer.blendMode];
        [newLayers addObject:newLayer];
    }
    return [[MTIMultilayerCompositingRecipe alloc] initWithKernel:self.kernel backgroundImage:backgroundImage layers:newLayers outputTextureDimensions:self.dimensions outputPixelFormat:self.outputPixelFormat];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:self.layers];
}

@end

@implementation MTIMultilayerCompositeKernel

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(MTIMultilayerCompositeKernelConfiguration *)configuration error:(NSError * __autoreleasing *)error {
    NSParameterAssert(configuration);
    MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.pixelFormat = configuration.outputPixelFormat;
    colorAttachmentDescriptor.blendingEnabled = NO;
    return [[MTIMultilayerCompositeKernelState alloc] initWithContext:context colorAttachmentDescriptor:colorAttachmentDescriptor error:error];
}

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image layers:(NSArray<MTILayer *> *)layers outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIMultilayerCompositingRecipe *receipt = [[MTIMultilayerCompositingRecipe alloc] initWithKernel:self
                                                                                     backgroundImage:image
                                                                                              layers:layers
                                                                             outputTextureDimensions:outputTextureDimensions
                                                                                   outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end

#import "MTIRenderGraphOptimization.h"

void MTIMultilayerCompositingRenderGraphNodeOptimize(MTIRenderGraphNode *node) {
    if ([node.image.promise isKindOfClass:[MTIMultilayerCompositingRecipe class]]) {
        MTIMultilayerCompositingRecipe *recipe = node.image.promise;
        MTIRenderGraphNode *lastNode = node.inputs.firstObject;
        MTIImage *lastImage = node.inputs.firstObject.image;
        if (lastNode.uniqueDependentCount == 1 && [lastImage.promise isKindOfClass:[MTIMultilayerCompositingRecipe class]]) {
            MTIMultilayerCompositingRecipe *lastPromise = lastImage.promise;
            NSArray<MTILayer *> *layers = recipe.layers;
            if (lastImage.cachePolicy == MTIImageCachePolicyTransient && lastPromise.outputPixelFormat == recipe.outputPixelFormat && recipe.kernel == lastPromise.kernel) {
                layers = [lastPromise.layers arrayByAddingObjectsFromArray:layers];
                MTIMultilayerCompositingRecipe *promise = [[MTIMultilayerCompositingRecipe alloc] initWithKernel:recipe.kernel
                                                                                                 backgroundImage:lastPromise.backgroundImage
                                                                                                          layers:layers
                                                                                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(lastPromise.backgroundImage.size)
                                                                                               outputPixelFormat:recipe.outputPixelFormat];
                NSMutableArray *inputs = [NSMutableArray arrayWithArray:lastNode.inputs];
                [node.inputs removeObjectAtIndex:0];
                [inputs addObjectsFromArray:node.inputs];
                node.inputs = inputs;
                node.image = [[MTIImage alloc] initWithPromise:promise samplerDescriptor:node.image.samplerDescriptor cachePolicy:node.image.cachePolicy];
            }
        }
    }
}
