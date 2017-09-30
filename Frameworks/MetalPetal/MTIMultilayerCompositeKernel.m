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

@interface MTIMultilayerCompositeKernelState: NSObject

@property (nonatomic,copy,readonly) NSDictionary<MTIBlendMode, MTIRenderPipeline *> *pipelines;

@property (nonatomic,copy,readonly) MTIRenderPipeline *passthroughRenderPipeline;

@end

@implementation MTIMultilayerCompositeKernelState

- (instancetype)initWithContext:(MTIContext *)context colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor error:(NSError **)inOutError {
    if (self = [super init]) {
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
        _passthroughRenderPipeline = [context renderPipelineWithDescriptor:renderPipelineDescriptor error:&error];
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

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

@end

@implementation MTIMultilayerCompositingRecipe

@synthesize dimensions = _dimensions;

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

- (NSArray<MTIImage *> *)dependencies {
    return [@[self.backgroundImage] arrayByAddingObjectsFromArray:[self.layers valueForKeyPath:@"content"]];
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
    
    MTIMultilayerCompositeKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel error:&error];
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
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    //render background
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:[kernelState passthroughRenderPipeline].state];
    [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
    [commandEncoder setFragmentTexture:backgroundImageResolution.texture atIndex:0];
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.backgroundImage.samplerDescriptor];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
    
    //render layers
    for (NSUInteger index = 0; index < self.layers.count; index += 1) {
        MTICompositingLayer *layer = self.layers[index];
        id<MTIImagePromiseResolution> contentResolution = layerContentResolutions[index];
        
        MTIVertices *vertices = [self verticesForRect:CGRectMake(-layer.size.width/2.0, -layer.size.height/2.0, layer.size.width, layer.size.height)];
        [commandEncoder setRenderPipelineState:[kernelState pipelineWithBlendMode:layer.blendMode].state];
        [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
        
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
        
        //opacity
        float opacity = layer.opacity;
        [commandEncoder setFragmentBytes:&opacity length:sizeof(float) atIndex:0];
        
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
        
        [contentResolution markAsConsumedBy:self];
    }
    
    //end encoding
    [commandEncoder endEncoding];
    
    [backgroundImageResolution markAsConsumedBy:self];

    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIMultilayerCompositeKernel *)kernel
                   backgroundImage:(MTIImage *)backgroundImage
                        layers:(NSArray<MTICompositingLayer *> *)layers
           outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    if (self = [super init]) {
        _backgroundImage = backgroundImage;
        _kernel = kernel;
        _layers = layers;
        _textureDescriptor = [outputTextureDescriptor newMTITextureDescriptor];
        _dimensions = (MTITextureDimensions){outputTextureDescriptor.width, outputTextureDescriptor.height, outputTextureDescriptor.depth};
    }
    return self;
}

@end

@interface MTIMultilayerCompositeKernel ()

@property (nonatomic,copy,readonly) MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor;

@end

@implementation MTIMultilayerCompositeKernel

- (instancetype)initWithPixelFormat:(MTLPixelFormat)format {
    if (self = [super init]) {
        MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
        colorAttachmentDescriptor.pixelFormat = format;
        colorAttachmentDescriptor.blendingEnabled = NO;
        _colorAttachmentDescriptor = colorAttachmentDescriptor;
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    return [[MTIMultilayerCompositeKernelState alloc] initWithContext:context colorAttachmentDescriptor:self.colorAttachmentDescriptor error:error];
}

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image layers:(NSArray<MTICompositingLayer *> *)layers outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    NSParameterAssert(outputTextureDescriptor.pixelFormat == self.colorAttachmentDescriptor.pixelFormat);
    MTIMultilayerCompositingRecipe *receipt = [[MTIMultilayerCompositingRecipe alloc] initWithKernel:self
                                                                                     backgroundImage:image
                                                                                              layers:layers
                                                                             outputTextureDescriptor:outputTextureDescriptor];
    return [[MTIImage alloc] initWithPromise:receipt];
}

- (MTLPixelFormat)pixelFormat {
    return self.colorAttachmentDescriptor.pixelFormat;
}

@end
