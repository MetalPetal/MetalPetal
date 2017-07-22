//
//  MTICVPixelBufferPromise.m
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import "MTICVPixelBufferPromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTITexturePool.h"
#import "MTIRenderPipeline.h"
#import <simd/simd.h>

static NSString * const MTIColorConversionVertexFunctionName   = @"colorConversionVertex";
static NSString * const MTIColorConversionFragmentFunctionName = @"colorConversionFragment";

static const float colorConversionVertexData[16] =
{
    -1.0, -1.0,  0.0, 1.0,
    1.0, -1.0,  1.0, 1.0,
    -1.0,  1.0,  0.0, 0.0,
    1.0,  1.0,  1.0, 0.0,
};

//Always use "struct X {}; typedef struct X X;" to define a struct, so that the struct can be encoded/archived with NSValue. ref: https://stackoverflow.com/a/12292033/1061004
struct ColorConversion {
    matrix_float3x3 matrix;
    vector_float3 offset;
};
typedef struct ColorConversion ColorConversion;

static const ColorConversion colorConversion = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.392, 2.017, },
        .columns[2] = { 1.596, -0.813, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};


@interface MTICVPixelBufferPromise ()

@property (nonatomic) CVPixelBufferRef pixelBuffer;

@end

@implementation MTICVPixelBufferPromise

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _textureDescriptor = [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO] newMTITextureDescriptor];
    }
    return self;
}

- (void)dealloc
{
    CVPixelBufferRelease(_pixelBuffer);
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (nullable MTIRenderPipeline *)colorConversionRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat context:(MTIContext *)context error:(NSError **)inOutError {
    
    NSError *error;
    id<MTLFunction> vertexFunction = [context functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIColorConversionVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIColorConversionFragmentFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.sampleCount = 1;
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    // CVMetalTextureCache: 420v, 1-2ms, 60fps
    // CVMetalTextureCache, 420f, 1-2ms, 60fps
    // CVMetalTextureCache: BGRA, 0.1ms, 60fps
    
    // CIImage: 420v, 5ms, 57fps
    // CIImage: 420f, 5ms, 57fps
    // CIImage: BGRA, 4ms, 58fps
    
    /* core image test
     id<MTLTexture> texture = [renderingContext.context.texturePool newRenderTargetForPromise:self];
     CIImage *image = [CIImage imageWithCVPixelBuffer:self.pixelBuffer];
     [renderingContext.context.coreImageContext render:image toMTLTexture:texture commandBuffer:renderingContext.commandBuffer bounds:image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
     return texture;
     */
    
#if COREVIDEO_SUPPORTS_METAL

    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(self.pixelBuffer);
    
    switch (pixelFormatType) {
        case kCVPixelFormatType_32BGRA:{
            CVMetalTextureRef metalTexture = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        renderingContext.context.coreVideoTextureCache,
                                                                        self.pixelBuffer,
                                                                        NULL,
                                                                        MTLPixelFormatBGRA8Unorm,
                                                                        CVPixelBufferGetWidth(self.pixelBuffer),
                                                                        CVPixelBufferGetHeight(self.pixelBuffer),
                                                                        0,
                                                                        &metalTexture);
            id<MTLTexture> texture = nil;
            if (status == kCVReturnSuccess) {
                texture = CVMetalTextureGetTexture(metalTexture);
                CFRelease(metalTexture);
            } else {
                NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:nil];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            return texture;
        } break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
            id<MTLTexture> textureY = nil;
            id<MTLTexture> textureCbCr = nil;
            
            {
                size_t width = CVPixelBufferGetWidthOfPlane(self.pixelBuffer, 0);
                size_t height = CVPixelBufferGetHeightOfPlane(self.pixelBuffer, 0);
                
                CVMetalTextureRef texture = NULL;
                CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                            renderingContext.context.coreVideoTextureCache,
                                                                            self.pixelBuffer,
                                                                            NULL,
                                                                            MTLPixelFormatR8Unorm,
                                                                            width,
                                                                            height,
                                                                            0,
                                                                            &texture);
                if (status == kCVReturnSuccess) {
#warning save to release texture?
                    textureY = CVMetalTextureGetTexture(texture);
                    CFRelease(texture);
                }
            }
            
            {
                size_t width = CVPixelBufferGetWidthOfPlane(self.pixelBuffer, 1);
                size_t height = CVPixelBufferGetHeightOfPlane(self.pixelBuffer, 1);
                
                CVMetalTextureRef texture = NULL;
                CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                            renderingContext.context.coreVideoTextureCache,
                                                                            self.pixelBuffer,
                                                                            NULL,
                                                                            MTLPixelFormatRG8Unorm,
                                                                            width,
                                                                            height,
                                                                            1,
                                                                            &texture);
                if (status == kCVReturnSuccess) {
                    textureCbCr = CVMetalTextureGetTexture(texture);
                    CFRelease(texture);
                }
            }
            
            CVMetalTextureCacheFlush(renderingContext.context.coreVideoTextureCache, 0);
            
            if (textureY && textureCbCr) {
                
                NSError *error = nil;
                
                id<MTLTexture> renderTarget = [renderingContext.context.texturePool newRenderTargetForPromise:self];
                
                MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
                renderPassDescriptor.colorAttachments[0].texture = renderTarget;
                renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
                renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
                
                MTIRenderPipeline *renderPipeline = [self colorConversionRenderPipelineWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat context:renderingContext.context error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                __auto_type renderCommandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                [renderCommandEncoder setRenderPipelineState:renderPipeline.state];
                [renderCommandEncoder setVertexBytes:colorConversionVertexData length:16*sizeof(float) atIndex:0];
                [renderCommandEncoder setFragmentTexture:textureY atIndex:0];
                [renderCommandEncoder setFragmentTexture:textureCbCr atIndex:1];
                [renderCommandEncoder setFragmentBytes:&colorConversion length:sizeof(colorConversion) atIndex:0];
                
                [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
                [renderCommandEncoder endEncoding];
                
                return renderTarget;
            } else {
                NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:nil];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } break;
        default:{
            NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorUnsupportedCVPixelBufferFormat userInfo:@{}];
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        } break;
    }
#else
    NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoDoesNotSupportMetal userInfo:@{}];
    if (inOutError) {
        *inOutError = error;
    }
    return nil;
#endif
}

@end
