//
//  MTIContext+Rendering.m
//  Pods
//
//  Created by YuAo on 23/07/2017.
//
//

#import "MTIContext+Rendering.h"
#import "MTIImageRenderingContext.h"
#import "MTIImage.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVertex.h"
#import "MTIRenderPipeline.h"
#import "MTIFilter.h"
#import "MTIDrawableRendering.h"
#import "MTIError.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@implementation MTIContext (Rendering)

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError * _Nullable __autoreleasing * _Nullable)inOutError {
#if COREVIDEO_SUPPORTS_METAL
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef renderTexture = NULL;
    CVReturn err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             self.coreVideoTextureCache,
                                                             pixelBuffer,
                                                             NULL,
                                                             resolution.texture.pixelFormat,
                                                             frameWidth,
                                                             frameHeight,
                                                             0,
                                                             &renderTexture);
    if (!renderTexture || err) {
        NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorCoreVideoMetalTextureCacheFailedToCreateTexture userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]}];
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    id<MTLTexture> metalTexture = CVMetalTextureGetTexture(renderTexture);
    id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
    [blitCommandEncoder copyFromTexture:resolution.texture
                            sourceSlice:0
                            sourceLevel:0
                           sourceOrigin:MTLOriginMake(0, 0, 0)
                             sourceSize:MTLSizeMake(resolution.texture.width, resolution.texture.height, resolution.texture.depth)
                              toTexture:metalTexture
                       destinationSlice:0
                       destinationLevel:0
                      destinationOrigin:MTLOriginMake(0, 0, 0)];
    [blitCommandEncoder endEncoding];
    
    [renderingContext.commandBuffer commit];
    
    CFRelease(renderTexture);
    CVMetalTextureCacheFlush(self.coreVideoTextureCache, 0);
    
    [resolution markAsConsumedBy:self];
    
    if (inOutError) {
        *inOutError = nil;
    }
    return YES;
#else
    NSError *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorCoreVideoDoesNotSupportMetal userInfo:@{}];
    if (inOutError) {
        *inOutError = error;
    }
    return NO;
#endif
}

- (nullable MTIRenderPipeline *)passthroughRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat error:(NSError **)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    NSError *error;
    id<MTLFunction> vertextFunction = [self functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName] error:&error];
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

- (BOOL)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [request.drawableProvider renderPassDescriptorForRequest:request];
    if (renderPassDescriptor == nil) {
        if (inOutError) {
            *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorEmptyDrawable userInfo:nil];
        }
        return NO;
    }
    
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
        return NO;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
    
    [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    id<MTLDrawable> drawable = [request.drawableProvider drawableForRequest:request];
    [renderingContext.commandBuffer presentDrawable:drawable];
    
    [renderingContext.commandBuffer commit];
    
    [resolution markAsConsumedBy:self];
    
    if (inOutError) {
        *inOutError = nil;
    }
    
    return YES;
}

- (CIImage *)createCIImageFromImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    MTIImage *persistentImage = [image imageWithCachePolicy:MTIImageCachePolicyPersistent];
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:persistentImage error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    [renderingContext.commandBuffer commit];
    CIImage *ciImage = [CIImage imageWithMTLTexture:resolution.texture options:@{}];
    objc_setAssociatedObject(ciImage, (__bridge const void *)(persistentImage), persistentImage, OBJC_ASSOCIATION_RETAIN);
    return ciImage;
}

- (CGImageRef)createCGImageFromImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, image.size.width, image.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}, (id)kCVPixelBufferCGImageCompatibilityKey: @YES}, &pixelBuffer);
    if (pixelBuffer) {
        NSError *error;
        [self renderImage:image toCVPixelBuffer:pixelBuffer error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return NULL;
        }
        CGImageRef image;
        OSStatus returnCode = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &image);
        CVPixelBufferRelease(pixelBuffer);
        if (returnCode != noErr) {
            if (inOutError) {
                *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorFailedToCreateCGImageFromCVPixelBuffer userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:returnCode userInfo:@{}]}];
            }
            return NULL;
        }
        return image;
    } else {
        if (inOutError) {
            *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorFailedToCreateCVPixelBuffer userInfo:@{}];
        }
        return NULL;
    }
}

@end
