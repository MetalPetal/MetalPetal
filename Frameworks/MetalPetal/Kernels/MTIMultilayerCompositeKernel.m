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
#import "MTIMask.h"
#import "MTIPixelFormat.h"
#import "MTIHasher.h"
#import "MTILock.h"

__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositeKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;
@property (nonatomic,readonly) NSUInteger rasterSampleCount;

@end

@implementation MTIMultilayerCompositeKernelConfiguration

- (instancetype)initWithOutputPixelFormat:(MTLPixelFormat)pixelFormat rasterSampleCount:(NSUInteger)rasterSampleCount {
    if (self = [super init]) {
        _outputPixelFormat = pixelFormat;
        _rasterSampleCount = rasterSampleCount;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<NSCopying>)identifier {
    return self;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _outputPixelFormat);
    MTIHasherCombine(&hasher, _rasterSampleCount);
    return MTIHasherFinalize(&hasher);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    MTIMultilayerCompositeKernelConfiguration *obj = object;
    if ([obj isKindOfClass:MTIMultilayerCompositeKernelConfiguration.class] && obj -> _outputPixelFormat == _outputPixelFormat && obj -> _rasterSampleCount == _rasterSampleCount) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface MTILayerRenderPipelineKey : NSObject <NSCopying> {
    BOOL _contentHasPremultipliedAlpha;
    BOOL _hasContentMask;
    BOOL _hasCompositingMask;
    BOOL _hasTintColor;
}
@property (nonatomic, copy, readonly) MTIBlendMode blendMode;
@end

@implementation MTILayerRenderPipelineKey

- (instancetype)initLayer:(MTILayer *)layer {
    if (self = [super init]) {
        _blendMode = layer.blendMode;
        _contentHasPremultipliedAlpha = layer.content.alphaType == MTIAlphaTypePremultiplied;
        _hasContentMask = layer.mask != nil;
        _hasCompositingMask = layer.compositingMask != nil;
        _hasTintColor = layer.tintColor.alpha > 0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MTILayerRenderPipelineKey class]]) {
        MTILayerRenderPipelineKey *other = object;
        return
        [other->_blendMode isEqualToString:_blendMode] &&
        other->_contentHasPremultipliedAlpha == _contentHasPremultipliedAlpha &&
        other->_hasContentMask == _hasContentMask &&
        other->_hasCompositingMask == _hasCompositingMask &&
        other->_hasTintColor == _hasTintColor;
    }
    return NO;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _blendMode.hash);
    MTIHasherCombine(&hasher, (uint64_t)_contentHasPremultipliedAlpha);
    MTIHasherCombine(&hasher, (uint64_t)_hasContentMask);
    MTIHasherCombine(&hasher, (uint64_t)_hasCompositingMask);
    MTIHasherCombine(&hasher, (uint64_t)_hasTintColor);
    return MTIHasherFinalize(&hasher);
}

- (MTIFunctionDescriptor *)createFragmentFunctionDescriptor:(BOOL)usesProgrammableBlending {
    MTIFunctionDescriptor *fragmentFunctionDescriptorForBlending;
    if (usesProgrammableBlending) {
        fragmentFunctionDescriptorForBlending = [MTIBlendModes functionDescriptorsForBlendMode:_blendMode].fragmentFunctionDescriptorForMultilayerCompositingFilterWithProgrammableBlending;
    } else {
        fragmentFunctionDescriptorForBlending = [MTIBlendModes functionDescriptorsForBlendMode:_blendMode].fragmentFunctionDescriptorForMultilayerCompositingFilterWithoutProgrammableBlending;
    }
    if (!fragmentFunctionDescriptorForBlending) {
        return nil;
    }
    MTLFunctionConstantValues *constants = [[MTLFunctionConstantValues alloc] init];
    [constants setConstantValue:&_contentHasPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::multilayer_composite_content_premultiplied"];
    [constants setConstantValue:&_hasContentMask type:MTLDataTypeBool withName:@"metalpetal::multilayer_composite_has_mask"];
    [constants setConstantValue:&_hasCompositingMask type:MTLDataTypeBool withName:@"metalpetal::multilayer_composite_has_compositing_mask"];
    [constants setConstantValue:&_hasTintColor type:MTLDataTypeBool withName:@"metalpetal::multilayer_composite_has_tint_color"];
    return [fragmentFunctionDescriptorForBlending functionDescriptorWithConstantValues:constants];
}

@end

__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositeKernelState: NSObject

@property (nonatomic,unsafe_unretained,readonly) MTIContext *context;

@property (nonatomic,readonly) NSUInteger rasterSampleCount;
@property (nonatomic,copy,readonly) MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor;

@property (nonatomic,copy,readonly) MTIRenderPipeline *passthroughRenderPipeline;
@property (nonatomic,copy,readonly) MTIRenderPipeline *unpremultiplyAlphaRenderPipeline;

@property (nonatomic,copy,readonly) MTIRenderPipeline *premultiplyAlphaInPlaceRenderPipeline;
@property (nonatomic,copy,readonly) MTIRenderPipeline *alphaToOneInPlaceRenderPipeline;

@property (nonatomic,strong,readonly) id<MTILocking> layerPipelineCacheLock;
@property (nonatomic,strong,readonly) NSMutableDictionary<MTILayerRenderPipelineKey *, MTIRenderPipeline *> *layerPipelines;

@end

@implementation MTIMultilayerCompositeKernelState

+ (MTIRenderPipeline *)renderPipelineWithFragmentFunctionName:(NSString *)fragmentFunctionName colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor rasterSampleCount:(NSUInteger)rasterSampleCount context:(MTIContext *)context error:(NSError * __autoreleasing *)inOutError {
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
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    if (@available(iOS 11.0, macOS 10.13, *)) {
        renderPipelineDescriptor.rasterSampleCount = rasterSampleCount;
    } else {
        renderPipelineDescriptor.sampleCount = rasterSampleCount;
    }

    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (instancetype)initWithContext:(MTIContext *)context
      colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor
              rasterSampleCount:(NSUInteger)rasterSampleCount
                          error:(NSError * __autoreleasing *)inOutError {
    if (self = [super init]) {
        NSError *error;
        _context = context;
        _rasterSampleCount = rasterSampleCount;
        _colorAttachmentDescriptor = [colorAttachmentDescriptor copy];
        
        _layerPipelines = [NSMutableDictionary dictionary];
        _layerPipelineCacheLock = MTILockCreate();
        
        _passthroughRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:MTIFilterPassthroughFragmentFunctionName colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _unpremultiplyAlphaRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:MTIFilterUnpremultiplyAlphaFragmentFunctionName colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        BOOL useProgrammableBlending = context.defaultLibrarySupportsProgrammableBlending && context.isProgrammableBlendingSupported;
        
        if (useProgrammableBlending) {
            _premultiplyAlphaInPlaceRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"premultiplyAlphaInPlace" colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            _alphaToOneInPlaceRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"alphaToOneInPlace" colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } else {
            _premultiplyAlphaInPlaceRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"premultiplyAlpha" colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            _alphaToOneInPlaceRenderPipeline = [MTIMultilayerCompositeKernelState renderPipelineWithFragmentFunctionName:@"alphaToOne" colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:rasterSampleCount context:context error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        }
    }
    return self;
}

- (MTIRenderPipeline *)renderPipelineForLayer:(MTILayer *)layer error:(NSError * __autoreleasing *)inOutError {
    MTILayerRenderPipelineKey *key = [[MTILayerRenderPipelineKey alloc] initLayer:layer];
    [self.layerPipelineCacheLock lock];
    @MTI_DEFER {
        [self.layerPipelineCacheLock unlock];
    };
    MTIRenderPipeline *pipeline = self.layerPipelines[key];
    if (pipeline) {
        return pipeline;
    } else {
        BOOL useProgrammableBlending = _context.defaultLibrarySupportsProgrammableBlending && _context.isProgrammableBlendingSupported;

        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        
        NSError *error = nil;
        id<MTLFunction> vertextFunction = [_context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"multilayerCompositeVertexShader"] error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        MTIFunctionDescriptor *fragmentFunctionDescriptorForBlending = [key createFragmentFunctionDescriptor:useProgrammableBlending];
        if (fragmentFunctionDescriptorForBlending == nil) {
            if (inOutError) {
                NSDictionary *info = @{@"blendMode": key.blendMode, @"programmableBlending": @(useProgrammableBlending)};
                *inOutError = MTIErrorCreate(MTIErrorBlendFunctionNotFound, info);
            }
            return nil;
        }
        
        id<MTLFunction> fragmentFunction = [_context functionWithDescriptor:fragmentFunctionDescriptorForBlending error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        renderPipelineDescriptor.vertexFunction = vertextFunction;
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        
        renderPipelineDescriptor.colorAttachments[0] = _colorAttachmentDescriptor;
        renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
        
        if (@available(iOS 11.0, macOS 10.13, *)) {
            renderPipelineDescriptor.rasterSampleCount = _rasterSampleCount;
        } else {
            renderPipelineDescriptor.sampleCount = _rasterSampleCount;
        }
        
        MTIRenderPipeline *pipeline = [_context renderPipelineWithDescriptor:renderPipelineDescriptor error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _layerPipelines[key] = pipeline;
        return pipeline;
    }
}

@end

@interface MTIMultilayerCompositingLayerVertices : NSObject<MTIGeometry> {
    MTIMultilayerCompositingLayerVertex _vertices[4];
}
@end

@implementation MTIMultilayerCompositingLayerVertices

- (instancetype)initWithVertices:(MTIMultilayerCompositingLayerVertex [4])vertices {
    if (self = [super init]) {
        _vertices[0] = vertices[0];
        _vertices[1] = vertices[1];
        _vertices[2] = vertices[2];
        _vertices[3] = vertices[3];
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (void)encodeDrawCallWithCommandEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder context:(nonnull id<MTIGeometryRenderingContext>)context {
    [commandEncoder setVertexBytes:_vertices length:sizeof(_vertices) atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
}

@end

__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTIImage *backgroundImage;

@property (nonatomic,strong,readonly) MTIMultilayerCompositeKernel *kernel;

@property (nonatomic,copy,readonly) NSArray<MTILayer *> *layers;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@property (nonatomic,readonly) NSUInteger rasterSampleCount;

@end

@implementation MTIMultilayerCompositingRecipe
@synthesize dimensions = _dimensions;
@synthesize dependencies = _dependencies;
@synthesize alphaType = _alphaType;

- (id<MTIGeometry>)verticesForRect:(CGRect)rect contentRegion:(CGRect)contentRegion flipOptions:(MTILayerFlipOptions)flipOptions {
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
    return [[MTIMultilayerCompositingLayerVertices alloc] initWithVertices:(MTIMultilayerCompositingLayerVertex [4]){
        { .position = {l, t, 0, 1} , .textureCoordinate = { contentL, contentT }, .positionInLayer = { 0, 1 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { contentR, contentT }, .positionInLayer = { 1, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { contentL, contentB }, .positionInLayer = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { contentR, contentB }, .positionInLayer = { 1, 0 } }
    }];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError *__autoreleasing  _Nullable *)error {
    BOOL useProgrammableBlending = renderingContext.context.defaultLibrarySupportsProgrammableBlending && renderingContext.context.isProgrammableBlendingSupported;
    if (useProgrammableBlending) {
        return [self resolveWithContext_programmableBlending:renderingContext error:error];
    } else {
        return [self resolveWithContext_no_programmableBlending:renderingContext error:error];
    }
}

- (MTIImagePromiseRenderTarget *)resolveWithContext_programmableBlending:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    
    NSError *error = nil;
    
    MTLPixelFormat pixelFormat = (_outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : _outputPixelFormat;

    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:_kernel configuration:[[MTIMultilayerCompositeKernelConfiguration alloc] initWithOutputPixelFormat:pixelFormat rasterSampleCount:_rasterSampleCount] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if (_rasterSampleCount > 1) {
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
        renderPassDescriptor.colorAttachments[0].texture = msaaTexture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionMultisampleResolve;
        renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget.texture;
    } else {
        renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    
    //render background
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
    [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:self.backgroundImage] atIndex:0];
    
    [MTIVertices.fullViewportSquareVertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTILayer *layer = self.layers[index];
        
        NSParameterAssert(layer.content.alphaType != MTIAlphaTypeUnknown);
        
        CGSize layerPixelSize = [layer sizeInPixelForBackgroundSize:self.backgroundImage.size];
        CGPoint layerPixelPosition = [layer positionInPixelForBackgroundSize:self.backgroundImage.size];
        
        id<MTIGeometry> geometry = [self verticesForRect:CGRectMake(-layerPixelSize.width/2.0, -layerPixelSize.height/2.0, layerPixelSize.width, layerPixelSize.height)
                                        contentRegion:CGRectMake(layer.contentRegion.origin.x/layer.content.size.width, layer.contentRegion.origin.y/layer.content.size.height, layer.contentRegion.size.width/layer.content.size.width, layer.contentRegion.size.height/layer.content.size.height)
                                          flipOptions:layer.contentFlipOptions];
        
        MTIRenderPipeline *renderPipeline = [kernelState renderPipelineForLayer:layer error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            [commandEncoder endEncoding];
            return nil;
        }
        
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
        [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.content] atIndex:0];
        
        if (layer.compositingMask) {
            NSParameterAssert(layer.compositingMask.content.alphaType != MTIAlphaTypeUnknown);
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.compositingMask.content] atIndex:1];
            [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.compositingMask.content] atIndex:1];
        }
        
        if (layer.mask) {
            NSParameterAssert(layer.mask.content.alphaType != MTIAlphaTypeUnknown);
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.mask.content] atIndex:2];
            [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.mask.content] atIndex:2];
        }
        
        //parameters
        MTIMultilayerCompositingLayerShadingParameters parameters;
        parameters.canvasSize = simd_make_float2(self.backgroundImage.size.width, self.backgroundImage.size.height);
        parameters.opacity = layer.opacity;
        parameters.compositingMaskComponent = (int)layer.compositingMask.component;
        parameters.compositingMaskUsesOneMinusValue = layer.compositingMask.mode == MTIMaskModeOneMinusMaskValue;
        parameters.compositingMaskHasPremultipliedAlpha = layer.compositingMask.content.alphaType == MTIAlphaTypePremultiplied;
        parameters.maskComponent = (int)layer.mask.component;
        parameters.maskUsesOneMinusValue = layer.mask.mode == MTIMaskModeOneMinusMaskValue;
        parameters.maskHasPremultipliedAlpha = layer.mask.content.alphaType == MTIAlphaTypePremultiplied;
        parameters.tintColor = MTIColorToFloat4(layer.tintColor);
        [commandEncoder setFragmentBytes:&parameters length:sizeof(parameters) atIndex:0];
        
        [geometry encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    }
    
    MTIRenderPipeline *outputAlphaTypeRenderPipeline = nil;
    switch (_alphaType) {
        case MTIAlphaTypeNonPremultiplied:
            break;
        case MTIAlphaTypeAlphaIsOne: {
            outputAlphaTypeRenderPipeline = kernelState.alphaToOneInPlaceRenderPipeline;
        } break;
        case MTIAlphaTypePremultiplied: {
            outputAlphaTypeRenderPipeline = kernelState.premultiplyAlphaInPlaceRenderPipeline;
        } break;
        default:
            NSAssert(NO, @"Unknown output alpha type.");
            break;
    }
    
    if (outputAlphaTypeRenderPipeline != nil) {
        [commandEncoder setRenderPipelineState:outputAlphaTypeRenderPipeline.state];
        [MTIVertices.fullViewportSquareVertices encodeDrawCallWithCommandEncoder:commandEncoder context:outputAlphaTypeRenderPipeline];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext_no_programmableBlending:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    
    NSError *error = nil;
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;
    
    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel configuration:[[MTIMultilayerCompositeKernelConfiguration alloc] initWithOutputPixelFormat:pixelFormat rasterSampleCount:_rasterSampleCount] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if (_rasterSampleCount > 1) {
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
        renderPassDescriptor.colorAttachments[0].texture = msaaTarget.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStoreAndMultisampleResolve;
        renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget.texture;
        [msaaTarget releaseTexture];
    } else {
        renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    
    //render background
    __auto_type __block commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
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
    [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:self.backgroundImage] atIndex:0];
    [MTIVertices.fullViewportSquareVertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    
    __auto_type rasterSampleCount = _rasterSampleCount;
    void (^prepareCommandEncoderForNextDraw)(void) = ^(void) {
        if (rasterSampleCount > 1) {
            //end current commend encoder then create a new one.
            [commandEncoder endEncoding];
            renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
            commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        } else {
            #if TARGET_OS_IOS || TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST || TARGET_OS_TV
                //we are on simulator/ios/macCatalyst, no texture barrier available, end current commend encoder then create a new one.
                [commandEncoder endEncoding];
                renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
                commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            #else
                //we are on macOS, use textureBarrier.
                #if TARGET_OS_OSX
                    [commandEncoder textureBarrier];
                #else
                    #error Unsupported OS
                #endif
            #endif
        }
    };
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        prepareCommandEncoderForNextDraw();
        if (!commandEncoder) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
            }
            return nil;
        }
        
        MTILayer *layer = self.layers[index];
        
        if (layer.compositingMask) {
            NSParameterAssert(layer.compositingMask.content.alphaType != MTIAlphaTypeUnknown);
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.compositingMask.content] atIndex:2];
            [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.compositingMask.content] atIndex:2];
        }
        
        if (layer.mask) {
            NSParameterAssert(layer.mask.content.alphaType != MTIAlphaTypeUnknown);
            [commandEncoder setFragmentTexture:[renderingContext resolvedTextureForImage:layer.mask.content] atIndex:3];
            [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.mask.content] atIndex:3];
        }
        
        NSParameterAssert(layer.content.alphaType != MTIAlphaTypeUnknown);
        
        CGSize layerPixelSize = [layer sizeInPixelForBackgroundSize:self.backgroundImage.size];
        CGPoint layerPixelPosition = [layer positionInPixelForBackgroundSize:self.backgroundImage.size];
        
        id<MTIGeometry> geometry = [self verticesForRect:CGRectMake(-layerPixelSize.width/2.0, -layerPixelSize.height/2.0, layerPixelSize.width, layerPixelSize.height)
                                        contentRegion:CGRectMake(layer.contentRegion.origin.x/layer.content.size.width, layer.contentRegion.origin.y/layer.content.size.height, layer.contentRegion.size.width/layer.content.size.width, layer.contentRegion.size.height/layer.content.size.height)
                                          flipOptions:layer.contentFlipOptions];
        
        MTIRenderPipeline *renderPipeline = [kernelState renderPipelineForLayer:layer error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            [commandEncoder endEncoding];
            return nil;
        }
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
        [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:layer.content] atIndex:0];
        
        [commandEncoder setFragmentTexture:renderTarget.texture atIndex:1];
        
        //parameters
        MTIMultilayerCompositingLayerShadingParameters parameters;
        parameters.canvasSize = simd_make_float2(self.backgroundImage.size.width, self.backgroundImage.size.height);
        parameters.opacity = layer.opacity;
        parameters.compositingMaskComponent = (int)layer.compositingMask.component;
        parameters.compositingMaskUsesOneMinusValue = layer.compositingMask.mode == MTIMaskModeOneMinusMaskValue;
        parameters.compositingMaskHasPremultipliedAlpha = layer.compositingMask.content.alphaType == MTIAlphaTypePremultiplied;
        parameters.maskComponent = (int)layer.mask.component;
        parameters.maskUsesOneMinusValue = layer.mask.mode == MTIMaskModeOneMinusMaskValue;
        parameters.maskHasPremultipliedAlpha = layer.mask.content.alphaType == MTIAlphaTypePremultiplied;
        parameters.tintColor = MTIColorToFloat4(layer.tintColor);
        [commandEncoder setFragmentBytes:&parameters length:sizeof(parameters) atIndex:0];
        
        [geometry encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    }
    
    MTIRenderPipeline *outputAlphaTypeRenderPipeline = nil;
    switch (_alphaType) {
        case MTIAlphaTypeNonPremultiplied:
            break;
        case MTIAlphaTypeAlphaIsOne: {
            outputAlphaTypeRenderPipeline = kernelState.alphaToOneInPlaceRenderPipeline;
        } break;
        case MTIAlphaTypePremultiplied: {
            outputAlphaTypeRenderPipeline = kernelState.premultiplyAlphaInPlaceRenderPipeline;
        } break;
        default:
            NSAssert(NO, @"Unknown output alpha type.");
            break;
    }
    
    if (outputAlphaTypeRenderPipeline != nil) {
        prepareCommandEncoderForNextDraw();
        if (!commandEncoder) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
            }
            return nil;
        }
        
        [commandEncoder setRenderPipelineState:outputAlphaTypeRenderPipeline.state];
        [commandEncoder setFragmentTexture:renderTarget.texture atIndex:0];
        [commandEncoder setFragmentSamplerState:[renderingContext resolvedSamplerStateForImage:_backgroundImage] atIndex:0];
        [MTIVertices.fullViewportSquareVertices encodeDrawCallWithCommandEncoder:commandEncoder context:outputAlphaTypeRenderPipeline];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIMultilayerCompositeKernel *)kernel
               backgroundImage:(MTIImage *)backgroundImage
                        layers:(NSArray<MTILayer *> *)layers
             rasterSampleCount:(NSUInteger)rasterSampleCount
               outputAlphaType:(MTIAlphaType)outputAlphaType
       outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
             outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        NSParameterAssert(rasterSampleCount >= 1);
        NSParameterAssert(backgroundImage);
        NSParameterAssert(kernel);
        NSParameterAssert(outputAlphaType != MTIAlphaTypeUnknown);
        _backgroundImage = backgroundImage;
        _alphaType = outputAlphaType;
        _kernel = kernel;
        _layers = layers;
        _dimensions = outputTextureDimensions;
        _outputPixelFormat = outputPixelFormat;
        _rasterSampleCount = rasterSampleCount;
        NSMutableArray *dependencies = [NSMutableArray arrayWithCapacity:layers.count + 1];
        [dependencies addObject:backgroundImage];
        for (MTILayer *layer in layers) {
            [dependencies addObject:layer.content];
            if (layer.compositingMask) {
                [dependencies addObject:layer.compositingMask.content];
            }
            if (layer.mask) {
                [dependencies addObject:layer.mask.content];
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
        MTIMask *mask = layer.mask;
        MTIMask *newMask = nil;
        if (compositingMask) {
            MTIImage *newCompositingMaskContent = dependencies[pointer];
            pointer += 1;
            newCompositingMask = [[MTIMask alloc] initWithContent:newCompositingMaskContent component:compositingMask.component mode:compositingMask.mode];
        }
        if (mask) {
            MTIImage *newMaskContent = dependencies[pointer];
            pointer += 1;
            newMask = [[MTIMask alloc] initWithContent:newMaskContent component:mask.component mode:mask.mode];
        }
        MTILayer *newLayer = [[MTILayer alloc] initWithContent:newContent contentRegion:layer.contentRegion contentFlipOptions:layer.contentFlipOptions mask:newMask compositingMask:newCompositingMask layoutUnit:layer.layoutUnit position:layer.position size:layer.size rotation:layer.rotation opacity:layer.opacity tintColor:layer.tintColor blendMode:layer.blendMode];
        [newLayers addObject:newLayer];
    }
    return [[MTIMultilayerCompositingRecipe alloc] initWithKernel:_kernel backgroundImage:backgroundImage layers:newLayers rasterSampleCount:_rasterSampleCount outputAlphaType:_alphaType outputTextureDimensions:_dimensions outputPixelFormat:_outputPixelFormat];
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
    return [[MTIMultilayerCompositeKernelState alloc] initWithContext:context colorAttachmentDescriptor:colorAttachmentDescriptor rasterSampleCount:configuration.rasterSampleCount error:error];
}

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image
                              layers:(NSArray<MTILayer *> *)layers
                   rasterSampleCount:(NSUInteger)rasterSampleCount
                     outputAlphaType:(MTIAlphaType)outputAlphaType
             outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
                   outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIMultilayerCompositingRecipe *receipt = [[MTIMultilayerCompositingRecipe alloc] initWithKernel:self
                                                                                     backgroundImage:image
                                                                                              layers:layers
                                                                                   rasterSampleCount:rasterSampleCount
                                                                                     outputAlphaType:outputAlphaType
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
                                                                                               rasterSampleCount:MAX(recipe.rasterSampleCount,lastPromise.rasterSampleCount)
                                                                                                 outputAlphaType:recipe.alphaType
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
