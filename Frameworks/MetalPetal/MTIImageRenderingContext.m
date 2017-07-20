//
//  MTIImageRenderingContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImageRenderingContext.h"
#import "MTIContext.h"
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIVertex.h"
#import "MTIRenderPipeline.h"
#import "MTIFilter.h"
#import "MTIDrawableRendering.h"
#import "MTIImage+Promise.h"
#import "MTITexturePool.h"
#import "MTITextureDescriptor.h"
@import AVFoundation;

NSString * const MTIColorConversionVertexFunctionName   = @"colorConversionVertex";
NSString * const MTIColorConversionFragmentFunctionName = @"colorConversionFragment";

@implementation MTIImageRenderingContext

- (instancetype)initWithContext:(MTIContext *)context {
    if (self = [super init]) {
        _context = context;
        _commandBuffer = [context.commandQueue commandBuffer];
    }
    return self;
}

@end

@implementation MTIContext (Rendering)

- (void)renderImage:(MTIImage *)image toPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError * _Nullable __autoreleasing * _Nullable)inOutError {
#if COREVIDEO_SUPPORTS_METAL
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    
#warning fetch texture from cache
    id<MTLTexture> texture = [image.promise resolveWithContext:renderingContext error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return;
    }
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef renderTexture = NULL;
    CVReturn err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             self.coreVideoTextureCache,
                                                             pixelBuffer,
                                                             NULL,
                                                             MTLPixelFormatBGRA8Unorm_sRGB,
                                                             frameWidth,
                                                             frameHeight,
                                                             0,
                                                             &renderTexture);
    if (!texture || err) {
        NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]}];
        if (inOutError) {
            *inOutError = error;
        }
        return;
    }
    
    id<MTLTexture> metalTexture = CVMetalTextureGetTexture(renderTexture);
    id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
    [blitCommandEncoder copyFromTexture:texture
                            sourceSlice:0
                            sourceLevel:0
                           sourceOrigin:MTLOriginMake(0, 0, 0)
                             sourceSize:MTLSizeMake(texture.width, texture.height, texture.depth)
                              toTexture:metalTexture
                       destinationSlice:0
                       destinationLevel:0
                      destinationOrigin:MTLOriginMake(0, 0, 0)];
    [blitCommandEncoder endEncoding];
    
    [renderingContext.commandBuffer commit];
    
    CFRelease(renderTexture);
    CVMetalTextureCacheFlush(self.coreVideoTextureCache, 0);
#else
    NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoDoesNotSupportMetal userInfo:@{}];
    if (inOutError) {
        *inOutError = error;
    }
    return;
#endif
}

- (nullable MTIRenderPipeline *)passthroughRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat error:(NSError **)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    NSError *error;
    id<MTLFunction> vertextFunction = [self functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    renderPipelineDescriptor.vertexFunction = vertextFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    renderPipelineDescriptor.colorAttachments[0].blendingEnabled = NO;
    
    return [self renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (nullable MTIRenderPipeline *)colorConversionRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat error:(NSError **)inOutError {
    
    NSError *error;
    id<MTLFunction> vertexFunction = [self functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIColorConversionVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self functionWithDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIColorConversionFragmentFunctionName] error:&error];
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

    return [self renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (void)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
#warning fetch texture from cache
    id<MTLTexture> texture = [image.promise resolveWithContext:renderingContext error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return;
    }
    
    id<MTLDrawable> drawable = [request.drawableProvider drawableForRequest:request];
    MTLRenderPassDescriptor *renderPassDescriptor = [request.drawableProvider renderPassDescriptorForRequest:request];
    
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    CGSize drawableSize = CGSizeMake(renderPassDescriptor.colorAttachments[0].texture.width, renderPassDescriptor.colorAttachments[0].texture.height);
    CGRect bounds = CGRectMake(0, 0, drawableSize.width, drawableSize.height);
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(image.size, bounds);
    switch (request.resizingMode) {
            case MTIDrawableRenderingResizingModeScale: {
                widthScaling = 1.0;
                heightScaling = 1.0;
            }; break;
            case MTIDrawableRenderingResizingModeAspect:
        {
            widthScaling = insetRect.size.width / drawableSize.width;
            heightScaling = insetRect.size.height / drawableSize.height;
        }; break;
            case MTIDrawableRenderingResizingModeAspectFill:
        {
            widthScaling = drawableSize.height / insetRect.size.height;
            heightScaling = drawableSize.width / insetRect.size.width;
        }; break;
    }
    MTIVertices *vertices = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {-widthScaling, -heightScaling, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {widthScaling, -heightScaling, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {-widthScaling, heightScaling, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {widthScaling, heightScaling, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4];
    
    MTIRenderPipeline *renderPipeline = [self passthroughRenderPipelineWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
    
    [commandEncoder setFragmentTexture:texture atIndex:0];
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    [renderingContext.commandBuffer presentDrawable:drawable];
    
    [renderingContext.commandBuffer commit];
}

- (void)renderCVPixelBuffer:(CVPixelBufferRef)pixelBuffer toMTLTexture:(id<MTLTexture>  _Nonnull __autoreleasing *)texture error:(NSError * _Nullable __autoreleasing *)inOutError
{
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (pixelFormatType == kCVPixelFormatType_32BGRA) {
        
        CVMetalTextureRef metalTexture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    self.coreVideoTextureCache,
                                                                    pixelBuffer,
                                                                    NULL,
                                                                    MTLPixelFormatBGRA8Unorm,
                                                                    CVPixelBufferGetWidth(pixelBuffer),
                                                                    CVPixelBufferGetHeight(pixelBuffer),
                                                                    0,
                                                                    &metalTexture);
        if (status == kCVReturnSuccess) {
            *texture = CVMetalTextureGetTexture(metalTexture);
            CFRelease(metalTexture);
        }
        
        CVMetalTextureCacheFlush(self.coreVideoTextureCache, 0);
        
    } else if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        
        id<MTLTexture> textureY = nil;
        id<MTLTexture> textureCbCr = nil;
        {
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
            
            CVMetalTextureRef texture = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        self.coreVideoTextureCache,
                                                                        pixelBuffer,
                                                                        NULL,
                                                                        MTLPixelFormatR8Unorm,
                                                                        width,
                                                                        height,
                                                                        0,
                                                                        &texture);
            if (status == kCVReturnSuccess) {
                textureY = CVMetalTextureGetTexture(texture);
                CFRelease(texture);
            }
        }
        {
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
            
            CVMetalTextureRef texture = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        self.coreVideoTextureCache,
                                                                        pixelBuffer,
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
        
        CVMetalTextureCacheFlush(self.coreVideoTextureCache, 0);
        
        if (textureY && textureCbCr) {
            
            NSError *error = nil;
            
            MTITextureDescriptor *textureDescriptor = [[MTITextureDescriptor alloc] initWithMTLTextureDescriptor:[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO]];
            
#warning Created a new Texture each frame (printed "[New Texture]" logs)
            MTIReusableTexture *reusableTexture = [self.texturePool newTextureWithDescriptor:textureDescriptor];
            
            MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
            renderPassDescriptor.colorAttachments[0].texture = reusableTexture.texture;
            renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
            renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

            MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
            
            MTIRenderPipeline *renderPipeline = [self colorConversionRenderPipelineWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return;
            }
            
            __auto_type renderCommandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderCommandEncoder setDepthStencilState:self.depthStencilState];
            [renderCommandEncoder setRenderPipelineState:renderPipeline.state];
            [renderCommandEncoder setVertexBuffer:self.colorConversionVertexBuffer offset:0 atIndex:0];
            [renderCommandEncoder setFragmentTexture:textureY atIndex:0];
            [renderCommandEncoder setFragmentTexture:textureCbCr atIndex:1];
            [renderCommandEncoder setFragmentBuffer:self.colorConversionFragmentBuffer offset:0 atIndex:0];

            [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
            [renderCommandEncoder endEncoding];
            
            [renderingContext.commandBuffer commit];
            
            *texture = reusableTexture.texture;
        
        } else {
            NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:nil];
            if (inOutError) {
                *inOutError = error;
            }
        }
        
    } else {
        NSError *error = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorCoreVideoDoesNotSupportedFormatType userInfo:@{}];
        if (inOutError) {
            *inOutError = error;
        }
    }
}

- (CIImage *)createCIImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    NSError *error = nil;
#warning fetch texture from cache
    id<MTLTexture> texture = [image.promise resolveWithContext:renderingContext error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    return [CIImage imageWithMTLTexture:texture options:@{}];
}

@end

