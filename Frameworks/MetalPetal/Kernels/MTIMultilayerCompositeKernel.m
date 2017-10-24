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
#import "MTIVector.h"
#import "MTIDefer.h"

@interface MTIMultilayerCompositeKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIMultilayerCompositeKernelConfiguration
@synthesize identifier = _identifier;

- (instancetype)initWithOutputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (self = [super init]) {
        _outputPixelFormat = pixelFormat;
        _identifier = @(pixelFormat).description;
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

@end

@implementation MTIMultilayerCompositeKernelState

+ (MTIRenderPipeline *)basicRenderPipelineWithFragmentFunctionName:(NSString *)fragmentFunctionName colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor context:(MTIContext *)context error:(NSError **)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    NSError *error;
    id<MTLFunction> vertextFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName] error:&error];
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
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (instancetype)initWithContext:(MTIContext *)context colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor error:(NSError **)inOutError {
    if (self = [super init]) {
        NSError *error;
        
        _passthroughRenderPipeline = [MTIMultilayerCompositeKernelState basicRenderPipelineWithFragmentFunctionName:MTIFilterPassthroughFragmentFunctionName colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        _unpremultiplyAlphaRenderPipeline = [MTIMultilayerCompositeKernelState basicRenderPipelineWithFragmentFunctionName:@"unpremultiplyAlpha" colorAttachmentDescriptor:colorAttachmentDescriptor context:context error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        NSMutableDictionary *pipelines = [NSMutableDictionary dictionary];
        for (MTIBlendMode mode in MTIBlendModeGetAllModes()) {
            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            
            NSError *error = nil;
            id<MTLFunction> vertextFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"multilayerCompositeVertexShader"] error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:[NSString stringWithFormat:@"multilayerComposite%@Blend",mode]] error:&error];
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

@implementation MTICompositingLayer

- (instancetype)initWithContent:(MTIImage *)content
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(CGFloat)rotation
                        opacity:(CGFloat)opacity
                      blendMode:(MTIBlendMode)blendMode {
    if (self = [super init]) {
        _content = content;
        _position = position;
        _size = size;
        _rotation = rotation;
        _opacity = opacity;
        _blendMode = blendMode;
    }
    return self;
}

@end

static simd_float4x4 MTIMakeOrthoMatrix(float left, float right, float bottom, float top, float near, float far) {
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    float scale = 2.0f;
    
    simd_float4x4 matrix;
    
    matrix.columns[0][0] = scale / r_l;
    matrix.columns[1][0] = 0.0f;
    matrix.columns[2][0] = 0.0f;
    matrix.columns[3][0] = tx;
    
    matrix.columns[0][1] = 0.0f;
    matrix.columns[1][1] = scale / t_b;
    matrix.columns[2][1] = 0.0f;
    matrix.columns[3][1] = ty;
    
    matrix.columns[0][2] = 0.0f;
    matrix.columns[1][2] = 0.0f;
    matrix.columns[2][2] = scale / f_n;
    matrix.columns[3][2] = tz;
    
    matrix.columns[0][3] = 0.0f;
    matrix.columns[1][3] = 0.0f;
    matrix.columns[2][3] = 0.0f;
    matrix.columns[3][3] = 1.0f;
    
    return matrix;
}

static simd_float4x4 MTIMakeTransformMatrix(CATransform3D transform) {
    simd_float4x4 matrix = simd_matrix(simd_make_float4((float)transform.m11,(float)transform.m12,(float)transform.m13,(float)transform.m14),
                                       simd_make_float4((float)transform.m21,(float)transform.m22,(float)transform.m23,(float)transform.m24),
                                       simd_make_float4((float)transform.m31,(float)transform.m32,(float)transform.m33,(float)transform.m34),
                                       simd_make_float4((float)transform.m41,(float)transform.m42,(float)transform.m43,(float)transform.m44));
    return matrix;
}

@interface MTIMultilayerCompositingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTIImage *backgroundImage;

@property (nonatomic,strong,readonly) MTIMultilayerCompositeKernel *kernel;

@property (nonatomic,copy,readonly) NSArray<MTICompositingLayer *> *layers;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIMultilayerCompositingRecipe
@synthesize dimensions = _dimensions;
@synthesize dependencies = _dependencies;

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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> backgroundImageResolution = [renderingContext resolutionForImage:self.backgroundImage error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    @MTI_DEFER {
        [backgroundImageResolution markAsConsumedBy:self];
    };
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;

    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel configuration:[MTIMultilayerCompositeKernelConfiguration configurationWithOutputPixelFormat:pixelFormat] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    //calc layerContentResolutions early to avoid recursive command encoding.
    NSMutableArray<id<MTIImagePromiseResolution>> *layerContentResolutions = [NSMutableArray array];
    for (MTICompositingLayer *layer in self.layers) {
        NSError *error = nil;
        id<MTIImagePromiseResolution> contentResolution = [renderingContext resolutionForImage:layer.content error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        [layerContentResolutions addObject:contentResolution];
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor]];

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    //render background
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    NSParameterAssert(self.backgroundImage.alphaType != MTIAlphaTypeUnknown);
    
    if (self.backgroundImage.alphaType == MTIAlphaTypePremultiplied) {
        [commandEncoder setRenderPipelineState:[kernelState unpremultiplyAlphaRenderPipeline].state];
    } else {
        [commandEncoder setRenderPipelineState:[kernelState passthroughRenderPipeline].state];
    }
    [commandEncoder setVertexBytes:vertices.bufferData.bytes length:vertices.bufferData.length atIndex:0];
    [commandEncoder setFragmentTexture:backgroundImageResolution.texture atIndex:0];
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.backgroundImage.samplerDescriptor];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    [commandEncoder drawPrimitives:vertices.primitiveType vertexStart:0 vertexCount:vertices.vertexCount];
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTICompositingLayer *layer = self.layers[index];
        id<MTIImagePromiseResolution> contentResolution = layerContentResolutions[index];
        
        MTIVertices *vertices = [self verticesForRect:CGRectMake(-layer.size.width/2.0, -layer.size.height/2.0, layer.size.width, layer.size.height)];
        [commandEncoder setRenderPipelineState:[kernelState pipelineWithBlendMode:layer.blendMode].state];
        [commandEncoder setVertexBytes:vertices.bufferData.bytes length:vertices.bufferData.length atIndex:0];
        
        //transformMatrix
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, layer.position.x - self.backgroundImage.size.width/2.0, layer.position.y - self.backgroundImage.size.height/2.0, 0);
        transform = CATransform3DRotate(transform, layer.rotation, 0, 0, 1);
        simd_float4x4 transformMatrix = MTIMakeTransformMatrix(transform);
        [commandEncoder setVertexBytes:&transformMatrix length:sizeof(transformMatrix) atIndex:1];
        
        //orthographicMatrix
        simd_float4x4 orthographicMatrix = MTIMakeOrthoMatrix(-self.backgroundImage.size.width/2.0, self.backgroundImage.size.width/2.0, -self.backgroundImage.size.height/2.0, self.backgroundImage.size.height/2.0, -1, 1);
        [commandEncoder setVertexBytes:&orthographicMatrix length:sizeof(orthographicMatrix) atIndex:2];
        
        [commandEncoder setFragmentTexture:contentResolution.texture atIndex:0];
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:layer.content.samplerDescriptor];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
        
        //parameters
        NSParameterAssert(layer.content.alphaType != MTIAlphaTypeUnknown);
        
        MTIMultilayerCompositingLayerShadingParameters parameters;
        parameters.opacity = layer.opacity;
        parameters.contentHasPremultipliedAlpha = (layer.content.alphaType == MTIAlphaTypePremultiplied);
        [commandEncoder setFragmentBytes:&parameters length:sizeof(parameters) atIndex:0];
        
        [commandEncoder drawPrimitives:vertices.primitiveType vertexStart:0 vertexCount:vertices.vertexCount];
        
        [contentResolution markAsConsumedBy:self];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (MTIAlphaType)alphaType {
    return MTIAlphaTypeNonPremultiplied;
}

- (instancetype)initWithKernel:(MTIMultilayerCompositeKernel *)kernel
               backgroundImage:(MTIImage *)backgroundImage
                        layers:(NSArray<MTICompositingLayer *> *)layers
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
        for (MTICompositingLayer *layer in layers) {
            [dependencies addObject:layer.content];
        }
        _dependencies = [dependencies copy];
    }
    return self;
}

@end

@implementation MTIMultilayerCompositeKernel

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(MTIMultilayerCompositeKernelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing *)error {
    NSParameterAssert(configuration);
    MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.pixelFormat = configuration.outputPixelFormat;
    colorAttachmentDescriptor.blendingEnabled = NO;
    return [[MTIMultilayerCompositeKernelState alloc] initWithContext:context colorAttachmentDescriptor:colorAttachmentDescriptor error:error];
}

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image layers:(NSArray<MTICompositingLayer *> *)layers outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIMultilayerCompositingRecipe *receipt = [[MTIMultilayerCompositingRecipe alloc] initWithKernel:self
                                                                                     backgroundImage:image
                                                                                              layers:layers
                                                                             outputTextureDimensions:outputTextureDimensions
                                                                                   outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
