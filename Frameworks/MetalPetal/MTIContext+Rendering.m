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
#import "MTIDefer.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIAlphaPremultiplicationFilter.h"
#import "MTICVMetalTextureCache.h"
#import "MTIContext+Internal.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "MTICoreImageRendering.h"
#import "MTIRenderTask.h"
#import "MTIImageRenderingContext+Internal.h"

@implementation MTIContext (Rendering)

+ (MTIRenderPipelineKernel *)premultiplyAlphaKernel {
    return MTIPremultiplyAlphaFilter.kernel;
}

+ (MTIRenderPipelineKernel *)unpremultiplyAlphaKernel {
    return MTIUnpremultiplyAlphaFilter.kernel;
}

+ (MTIRenderPipelineKernel *)passthroughKernel {
    return MTIRenderPipelineKernel.passthroughRenderPipelineKernel;
}

- (BOOL)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * __autoreleasing *)inOutError {
    MTIRenderTask *renderTask = [self startTaskToRenderImage:image toDrawableWithRequest:request error:inOutError];
    if (renderTask) {
        return YES;
    }
    return NO;
}

static const void * const MTICIImageMTIImageAssociationKey = &MTICIImageMTIImageAssociationKey;

- (CIImage *)createCIImageFromImage:(MTIImage *)image options:(MTICIImageCreationOptions *)options error:(NSError * __autoreleasing *)inOutError {
    [self lockForRendering];
    @MTI_DEFER {
        [self unlockForRendering];
    };
    
    NSParameterAssert(image.alphaType != MTIAlphaTypeUnknown);
    
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    MTIImage *persistentImage = [image imageWithCachePolicy:MTIImageCachePolicyPersistent];
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:persistentImage error:&error];
    @MTI_DEFER {
        [resolution markAsConsumedBy:self];
    };
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    [renderingContext.commandBuffer commit];
    [renderingContext.commandBuffer waitUntilScheduled];
    
    CIImage *ciImage = [CIImage imageWithMTLTexture:resolution.texture options:@{kCIImageColorSpace: (id)options.colorSpace ?: [NSNull null]}];
    if (options.isFlipped) {
        ciImage = [ciImage imageByApplyingOrientation:4];
    }
    
    if (image.alphaType == MTIAlphaTypeNonPremultiplied) {
        //ref: https://developer.apple.com/documentation/coreimage/ciimage/1645894-premultiplyingalpha
        //Premultiplied alpha speeds up the rendering of images, so Core Image filters require that input image data be premultiplied. If you have an image without premultiplied alpha that you want to feed into a filter, use this method before applying the filter.
        ciImage = [ciImage imageByPremultiplyingAlpha];
    }
    objc_setAssociatedObject(ciImage, MTICIImageMTIImageAssociationKey, persistentImage, OBJC_ASSOCIATION_RETAIN);
    return ciImage;
}

- (CIImage *)createCIImageFromImage:(MTIImage *)image error:(NSError * __autoreleasing *)inOutError {
    return [self createCIImageFromImage:image options:MTICIImageCreationOptions.defaultOptions error:inOutError];
}

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)inOutError {
    MTIRenderTask *renderTask = [self startTaskToRenderImage:image toCVPixelBuffer:pixelBuffer sRGB:sRGB error:inOutError];
    if (renderTask) {
        return YES;
    }
    return NO;
}

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError * __autoreleasing *)inOutError {
    return [self renderImage:image toCVPixelBuffer:pixelBuffer sRGB:NO error:inOutError];
}

- (CGImageRef)createCGImageFromImage:(MTIImage *)image error:(NSError * __autoreleasing *)inOutError {
    return [self createCGImageFromImage:image sRGB:NO error:inOutError];
}

- (CGImageRef)createCGImageFromImage:(MTIImage *)image sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)inOutError {
    CGImageRef outImage = NULL;
    __unused MTIRenderTask *renderTask = [self startTaskToCreateCGImage:&outImage fromImage:image sRGB:sRGB error:inOutError];
    return outImage;
}

- (MTIRenderTask *)startTaskToCreateCGImage:(CGImageRef  _Nullable *)outImage fromImage:(MTIImage *)image sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)error {
    return [self startTaskToCreateCGImage:outImage fromImage:image sRGB:sRGB error:error completion:nil];
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)error {
    return [self startTaskToRenderImage:image toCVPixelBuffer:pixelBuffer sRGB:sRGB error:error completion:nil];
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * __autoreleasing *)error {
    return [self startTaskToRenderImage:image toDrawableWithRequest:request error:error completion:nil];
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)inOutError completion:(void (^)(MTIRenderTask *))completion {
   return [self startTaskToRenderImage:image
                       toCVPixelBuffer:pixelBuffer
                                  sRGB:sRGB
                  destinationAlphaType:MTIAlphaTypePremultiplied
                                 error:inOutError
                            completion:completion];
}

- (nullable MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB destinationAlphaType:(MTIAlphaType)destinationAlphaType error:(NSError * __autoreleasing *)inOutError completion:(nullable void (^)(MTIRenderTask *task))completion {
    [self lockForRendering];
    @MTI_DEFER {
        [self unlockForRendering];
    };
    
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    @MTI_DEFER {
        [resolution markAsConsumedBy:self];
    };
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    MTLPixelFormat targetPixelFormat;
    switch (pixelFormatType) {
        case kCVPixelFormatType_32BGRA: {
            targetPixelFormat = sRGB ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm;
        } break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
            if (renderingContext.context.isYCbCrPixelFormatSupported) {
                targetPixelFormat = sRGB ? MTIPixelFormatYCBCR8_420_2P_sRGB : MTIPixelFormatYCBCR8_420_2P;
            } else {
                NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } break;
        case kCVPixelFormatType_64RGBAHalf: {
            targetPixelFormat = MTLPixelFormatRGBA16Float;
        } break;
        case kCVPixelFormatType_128RGBAFloat: {
            targetPixelFormat = MTLPixelFormatRGBA32Float;
        } break;
        case kCVPixelFormatType_OneComponent8: {
            #if TARGET_OS_IPHONE
            targetPixelFormat = sRGB ? MTLPixelFormatR8Unorm_sRGB : MTLPixelFormatR8Unorm;
            #else
            NSParameterAssert(!sRGB); //R8Unorm_sRGB texture is not available on macOS.
            if (sRGB) {
                NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            targetPixelFormat = sRGB ? MTLPixelFormatInvalid : MTLPixelFormatR8Unorm;
            #endif
        } break;
        case kCVPixelFormatType_OneComponent16Half: {
            targetPixelFormat = MTLPixelFormatR16Float;
        } break;
        case kCVPixelFormatType_OneComponent32Float: {
            targetPixelFormat = MTLPixelFormatR32Float;
        } break;
        default: {
            NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        } break;
    }
    
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:targetPixelFormat width:frameWidth height:frameHeight mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTICVMetalTexture> renderTexture = [self.coreVideoTextureBridge newTextureWithCVImageBuffer:pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
    if (!renderTexture || error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLTexture> metalTexture = renderTexture.texture;
    
    if (resolution.texture.pixelFormat == targetPixelFormat &&
        (image.alphaType == destinationAlphaType || image.alphaType == MTIAlphaTypeAlphaIsOne) &&
        resolution.texture.width == frameWidth &&
        resolution.texture.height == frameHeight)
    {
        //Blit
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
        
        MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
        if (completion) {
            [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                completion(task);
            }];
        }
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return task;
    } else {
        //Render
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDescriptor.colorAttachments[0].texture = metalTexture;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        MTIVertices *vertices = [MTIVertices squareVerticesForRect:CGRectMake(-1, -1, 2, 2)];
        
        NSParameterAssert(image.alphaType != MTIAlphaTypeUnknown);
        
        //Prefers premultiplied alpha here.
        MTIRenderPipelineKernel *kernel;
        if (image.alphaType == MTIAlphaTypeNonPremultiplied && destinationAlphaType == MTIAlphaTypePremultiplied) {
            kernel = MTIContext.premultiplyAlphaKernel;
        } else if (image.alphaType == MTIAlphaTypePremultiplied && destinationAlphaType == MTIAlphaTypeNonPremultiplied) {
            kernel = MTIContext.unpremultiplyAlphaKernel;
        } else {
            kernel = MTIContext.passthroughKernel;
        }
        
        MTIRenderPipelineKernelConfiguration *configuration = [[MTIRenderPipelineKernelConfiguration alloc] initWithColorAttachmentPixelFormat:metalTexture.pixelFormat];
        MTIRenderPipeline *renderPipeline = [self kernelStateForKernel:kernel configuration:configuration error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
        
        [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];

        [commandEncoder endEncoding];
        
        MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
        if (completion) {
            [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                completion(task);
            }];
        }
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return task;
    }
}

- (MTIRenderTask *)startTaskToCreateCGImage:(CGImageRef *)outImage fromImage:(MTIImage *)image sRGB:(BOOL)sRGB error:(NSError * __autoreleasing *)inOutError completion:(void (^)(MTIRenderTask *))completion {
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn errorCode = CVPixelBufferCreate(kCFAllocatorDefault, image.size.width, image.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}, (id)kCVPixelBufferCGImageCompatibilityKey: @YES}, &pixelBuffer);
    if (errorCode == kCVReturnSuccess && pixelBuffer) {
        NSError *error;
        MTIRenderTask *renderTask = [self startTaskToRenderImage:image toCVPixelBuffer:pixelBuffer sRGB:sRGB error:&error completion:completion];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        OSStatus returnCode = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, outImage);
        CVPixelBufferRelease(pixelBuffer);
        if (returnCode != noErr) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCGImageFromCVPixelBuffer, @{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:returnCode userInfo:nil]});
            }
            return nil;
        }
        return renderTask;
    } else {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCVPixelBuffer, @{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:errorCode userInfo:nil]});
        }
        return nil;
    }
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * __autoreleasing *)inOutError completion:(void (^)(MTIRenderTask *))completion {
    [self lockForRendering];
    @MTI_DEFER {
        [self unlockForRendering];
    };
    
    id<MTIDrawableProvider> drawableProvider = request.drawableProvider;
    
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    @MTI_DEFER {
        [resolution markAsConsumedBy:self];
    };
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [drawableProvider renderPassDescriptorForRequest:request];
    if (renderPassDescriptor == nil) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorEmptyDrawable, nil);
        }
        return nil;
    }
    
    if (renderPassDescriptor.colorAttachments[0].texture == nil) {
        NSAssert(NO, @"Rendering image to drawable: no texture found on color attachment 0. This could happen when the drawable size is less than 16x16 pixels on some devices.");
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorEmptyDrawableTexture, @{NSLocalizedFailureReasonErrorKey: @"Rendering image to drawable: no texture found on color attachment 0. This could happen when the drawable size is less than 16x16 pixels on some devices."});
        }
        return nil;
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
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
    
    NSParameterAssert(image.alphaType != MTIAlphaTypeUnknown);
    
    //iOS drawables always require premultiplied alpha.
    MTIRenderPipelineKernel *kernel;
    if (image.alphaType == MTIAlphaTypeNonPremultiplied) {
        kernel = MTIContext.premultiplyAlphaKernel;
    } else {
        kernel = MTIContext.passthroughKernel;
    }
    
    MTIRenderPipelineKernelConfiguration *configuration = [[MTIRenderPipelineKernelConfiguration alloc] initWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat];
    MTIRenderPipeline *renderPipeline = [self kernelStateForKernel:kernel configuration:configuration error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    
    [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
    
    [commandEncoder endEncoding];
    
    id<MTLDrawable> drawable = [drawableProvider drawableForRequest:request];
    [renderingContext.commandBuffer presentDrawable:drawable];
    
    MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
    if (completion) {
        [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
            completion(task);
        }];
    }
    [renderingContext.commandBuffer commit];
    [renderingContext.commandBuffer waitUntilScheduled];
    
    return task;
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toTexture:(id<MTLTexture>)texture destinationAlphaType:(MTIAlphaType)destinationAlphaType error:(NSError * __autoreleasing *)inOutError completion:(void (^)(MTIRenderTask * _Nonnull))completion {
    NSParameterAssert(texture);
    NSParameterAssert(texture.device == self.device);
    if (texture.device != self.device) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorCrossDeviceRendering, nil);
        }
        return nil;
    }
    
    [self lockForRendering];
    @MTI_DEFER {
        [self unlockForRendering];
    };
    
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    @MTI_DEFER {
        [resolution markAsConsumedBy:self];
    };
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    if (resolution.texture.pixelFormat == texture.pixelFormat &&
        (image.alphaType == destinationAlphaType || image.alphaType == MTIAlphaTypeAlphaIsOne) &&
        resolution.texture.width == texture.width &&
        resolution.texture.height == texture.height &&
        resolution.texture.depth == texture.depth)
    {
        //Blit
        id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
        [blitCommandEncoder copyFromTexture:resolution.texture
                                sourceSlice:0
                                sourceLevel:0
                               sourceOrigin:MTLOriginMake(0, 0, 0)
                                 sourceSize:MTLSizeMake(resolution.texture.width, resolution.texture.height, resolution.texture.depth)
                                  toTexture:texture
                           destinationSlice:0
                           destinationLevel:0
                          destinationOrigin:MTLOriginMake(0, 0, 0)];
        [blitCommandEncoder endEncoding];
        
        MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
        if (completion) {
            [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                completion(task);
            }];
        }
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return task;
    } else {
        //Render
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDescriptor.colorAttachments[0].texture = texture;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        MTIVertices *vertices = [MTIVertices squareVerticesForRect:CGRectMake(-1, -1, 2, 2)];
        
        NSParameterAssert(image.alphaType != MTIAlphaTypeUnknown);
        
        //Prefers premultiplied alpha here.
        MTIRenderPipelineKernel *kernel;
        if (image.alphaType == MTIAlphaTypeNonPremultiplied && destinationAlphaType == MTIAlphaTypePremultiplied) {
            kernel = MTIContext.premultiplyAlphaKernel;
        } else if (image.alphaType == MTIAlphaTypePremultiplied && destinationAlphaType == MTIAlphaTypeNonPremultiplied) {
            kernel = MTIContext.unpremultiplyAlphaKernel;
        } else {
            kernel = MTIContext.passthroughKernel;
        }
        
        MTIRenderPipelineKernelConfiguration *configuration = [[MTIRenderPipelineKernelConfiguration alloc] initWithColorAttachmentPixelFormat:texture.pixelFormat];
        MTIRenderPipeline *renderPipeline = [self kernelStateForKernel:kernel configuration:configuration error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:renderPipeline.state];
        
        [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
        
        [vertices encodeDrawCallWithCommandEncoder:commandEncoder context:renderPipeline];
        
        [commandEncoder endEncoding];
        
        MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
        if (completion) {
            [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                completion(task);
            }];
        }
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return task;
    }
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image error:(NSError * __autoreleasing *)inOutError completion:(void (^)(MTIRenderTask * _Nonnull))completion {
    [self lockForRendering];
    @MTI_DEFER {
        [self unlockForRendering];
    };
    
    MTIImageRenderingContext *renderingContext = [[MTIImageRenderingContext alloc] initWithContext:self];
    
    NSError *error = nil;
    id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
    @MTI_DEFER {
        [resolution markAsConsumedBy:self];
    };
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTIRenderTask *task = [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
    if (completion) {
        [renderingContext.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
            completion(task);
        }];
    }
    [renderingContext.commandBuffer commit];
    [renderingContext.commandBuffer waitUntilScheduled];
    return task;
}

@end
