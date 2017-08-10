//
//  MTICVPixelBufferPromise.m
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import "MTICVPixelBufferPromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIContext.h"
#import "MTIRenderPipeline.h"
#import "MTIComputePipeline.h"
#import "MTIError.h"
#import <simd/simd.h>

static NSString * const MTIColorConversionVertexFunctionName   = @"colorConversionVertex";
static NSString * const MTIColorConversionFragmentFunctionName = @"colorConversionFragment";
static NSString * const MTIColorConversionKernelFunctionName   = @"colorConversion";

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

// BT.601
static const ColorConversion kColorConversion601 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.392, 2.017, },
        .columns[2] = { 1.596, -0.813, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};

// BT.601 Full Range
static const ColorConversion kColorConversion601FullRange = {
    .matrix = {
        .columns[0] = { 1.000,  1.000, 1.000, },
        .columns[1] = { 0.000, -0.343, 1.765, },
        .columns[2] = { 1.400, -0.711, 0.000, },
    },
    .offset = { 0.0, -0.5, -0.5 },
};

// BT.709
static const ColorConversion kColorConversion709 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.213, 2.112, },
        .columns[2] = { 1.793, -0.533, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};

// BT.709 Full Range: vacancy

@interface MTICVPixelBufferPromise ()

@property (nonatomic) CVPixelBufferRef pixelBuffer;

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

@end

@implementation MTICVPixelBufferPromise

@synthesize dimensions = _dimensions;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        NSParameterAssert(pixelBuffer);
        
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _dimensions = (MTITextureDimensions){CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 1};
        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO];
        descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        _textureDescriptor = [descriptor newMTITextureDescriptor];
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

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (nullable MTIRenderPipeline *)colorConversionRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat context:(MTIContext *)context error:(NSError **)inOutError {
    
    NSError *error;
    id<MTLFunction> vertexFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionFragmentFunctionName] error:&error];
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

- (nullable MTIComputePipeline *)colorConversionComputePipelineWithContext:(MTIContext *)context error:(NSError **)inOutError
{
    NSError *error;
    id<MTLFunction> computeFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionKernelFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLComputePipelineDescriptor *computePipelineDescriptor = [[MTLComputePipelineDescriptor alloc] init];
    computePipelineDescriptor.computeFunction = computeFunction;
    
    return [context computePipelineWithDescriptor:computePipelineDescriptor error:inOutError];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    
    /* Core Image test
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
    CIImage *image = [CIImage imageWithCVPixelBuffer:self.pixelBuffer];
     [renderingContext.context.coreImageContext render:image toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
    return renderTarget;
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
                NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:nil];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            CVMetalTextureCacheFlush(renderingContext.context.coreVideoTextureCache, 0);
            return [renderingContext.context newRenderTargetWithTexture:texture];
        } break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
            
            BOOL isFullYUVRange = pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ? YES : NO;
            
            ColorConversion const *preferredConversion = nil;
            CFTypeRef colorAttachments = CVBufferGetAttachment(self.pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
            if (colorAttachments != NULL) {
                if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                    if (isFullYUVRange) {
                        preferredConversion = &kColorConversion601FullRange;
                    } else {
                        preferredConversion = &kColorConversion601;
                    }
                } else {
                    preferredConversion = &kColorConversion709;
                }
            } else {
                if (isFullYUVRange) {
                    preferredConversion = &kColorConversion601FullRange;
                } else {
                    preferredConversion = &kColorConversion601;
                }
            }
            
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
            
                /* Compute Pipeline test
                NSError *error = nil;
                
                size_t width = CVPixelBufferGetWidth(self.pixelBuffer);
                size_t height = CVPixelBufferGetHeight(self.pixelBuffer);
                
                MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
                
                MTIComputePipeline *computePipeline = [self colorConversionComputePipelineWithContext:renderingContext.context error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                __auto_type computeCommandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
                [computeCommandEncoder setComputePipelineState:computePipeline.state];
                [computeCommandEncoder setTexture:textureY atIndex:0];
                [computeCommandEncoder setTexture:textureCbCr atIndex:1];
                [computeCommandEncoder setTexture:renderTarget.texture atIndex:2];
                [computeCommandEncoder setBytes:preferredConversion length:sizeof(ColorConversion) atIndex:0];
                
                MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
                MTLSize threadgroups = MTLSizeMake(width / threadsPerThreadgroup.width,
                                                   height / threadsPerThreadgroup.height,
                                                   1);
                [computeCommandEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
                [computeCommandEncoder endEncoding];
                
                return renderTarget;
                */
                
                // Render Pipeline
                NSError *error = nil;
                
                MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
                
                MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
                renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
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
                [renderCommandEncoder setFragmentBytes:preferredConversion length:sizeof(ColorConversion) atIndex:0];
                [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
                [renderCommandEncoder endEncoding];
                
                return renderTarget;
            } else {
                NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:nil];
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } break;
        default:{
            NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorUnsupportedCVPixelBufferFormat userInfo:@{}];
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        } break;
    }
#else
    NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorCoreVideoDoesNotSupportMetal userInfo:@{}];
    if (inOutError) {
        *inOutError = error;
    }
    return nil;
#endif
}

@end
