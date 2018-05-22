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

@implementation MTIContext (Rendering)

+ (MTIRenderPipelineKernel *)premultiplyAlphaKernel {
    return MTIPremultiplyAlphaFilter.kernel;
}

+ (MTIRenderPipelineKernel *)passthroughKernel {
    return MTIRenderPipelineKernel.passthroughRenderPipelineKernel;
}

- (BOOL)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError * _Nullable __autoreleasing *)inOutError {
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
        return NO;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [request.drawableProvider renderPassDescriptorForRequest:request];
    if (renderPassDescriptor == nil) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorEmptyDrawable, nil);
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
        return NO;
    }
    
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setVertexBytes:vertices.bufferBytes length:vertices.bufferLength atIndex:0];
    
    [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    [commandEncoder drawPrimitives:vertices.primitiveType vertexStart:0 vertexCount:vertices.vertexCount];
    [commandEncoder endEncoding];
    
    id<MTLDrawable> drawable = [request.drawableProvider drawableForRequest:request];
    [renderingContext.commandBuffer presentDrawable:drawable];
    
    [renderingContext.commandBuffer commit];
    [renderingContext.commandBuffer waitUntilScheduled];
    
    return YES;
}

static const void * const MTICIImageMTIImageAssociationKey = &MTICIImageMTIImageAssociationKey;

- (CIImage *)createCIImageFromImage:(MTIImage *)image options:(MTICIImageCreationOptions *)options error:(NSError * _Nullable __autoreleasing *)inOutError {
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
        if (@available(iOS 10.0, *)) {
            ciImage = [ciImage imageByPremultiplyingAlpha];
        } else {
            CIFilter *premultiplyFilter = [CIFilter filterWithName:@"CIPremultiply"];
            NSAssert(premultiplyFilter, @"");
            if (premultiplyFilter) {
                [premultiplyFilter setValue:ciImage forKey:kCIInputImageKey];
                ciImage = premultiplyFilter.outputImage;
            }
        }
    }
    objc_setAssociatedObject(ciImage, MTICIImageMTIImageAssociationKey, persistentImage, OBJC_ASSOCIATION_RETAIN);
    return ciImage;
}

- (CIImage *)createCIImageFromImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    return [self createCIImageFromImage:image options:MTICIImageCreationOptions.defaultOptions error:inOutError];
}

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB error:(NSError * _Nullable __autoreleasing * _Nullable)inOutError {
    MTIRenderTask *renderTask = [self startTaskToRenderImage:image toCVPixelBuffer:pixelBuffer sRGB:sRGB error:inOutError];
    if (renderTask) {
        return YES;
    }
    return NO;
}

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError * _Nullable __autoreleasing * _Nullable)inOutError {
    return [self renderImage:image toCVPixelBuffer:pixelBuffer sRGB:NO error:inOutError];
}

- (CGImageRef)createCGImageFromImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    return [self createCGImageFromImage:image sRGB:NO error:inOutError];
}

- (CGImageRef)createCGImageFromImage:(MTIImage *)image sRGB:(BOOL)sRGB error:(NSError * _Nullable __autoreleasing *)inOutError {
    CGImageRef outImage = NULL;
    __unused MTIRenderTask *renderTask = [self startTaskToCreateCGImage:&outImage fromImage:image sRGB:sRGB error:inOutError];
    return outImage;
}

- (MTIRenderTask *)startTaskToRenderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer sRGB:(BOOL)sRGB error:(NSError * _Nullable __autoreleasing *)inOutError {
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
            if (MTIDeviceSupportsYCBCRPixelFormat(renderingContext.context.device)) {
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
            targetPixelFormat = sRGB ? MTLPixelFormatR8Unorm_sRGB : MTLPixelFormatR8Unorm;
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
    
    MTICVMetalTexture *renderTexture = [self.coreVideoTextureCache newTextureWithCVImageBuffer:pixelBuffer attributes:NULL pixelFormat:targetPixelFormat width:frameWidth height:frameHeight planeIndex:0 error:&error];
    if (!renderTexture || error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLTexture> metalTexture = renderTexture.texture;
    
    if (resolution.texture.pixelFormat == targetPixelFormat &&
        (image.alphaType == MTIAlphaTypePremultiplied || image.alphaType == MTIAlphaTypeAlphaIsOne) &&
        (size_t)image.size.width == frameWidth &&
        (size_t)image.size.height == frameHeight)
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
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
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
        if (image.alphaType == MTIAlphaTypeNonPremultiplied) {
            kernel = MTIContext.premultiplyAlphaKernel;
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
        [commandEncoder setVertexBytes:vertices.bufferBytes length:vertices.bufferLength atIndex:0];
        
        [commandEncoder setFragmentTexture:resolution.texture atIndex:0];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
        
        [commandEncoder drawPrimitives:vertices.primitiveType vertexStart:0 vertexCount:vertices.vertexCount];
        [commandEncoder endEncoding];
        
        [renderingContext.commandBuffer commit];
        [renderingContext.commandBuffer waitUntilScheduled];
        return [[MTIRenderTask alloc] initWithCommandBuffer:renderingContext.commandBuffer];
    }
}

- (MTIRenderTask *)startTaskToCreateCGImage:(CGImageRef *)outImage fromImage:(MTIImage *)image sRGB:(BOOL)sRGB error:(NSError * _Nullable __autoreleasing *)inOutError {
    CVPixelBufferRef pixelBuffer;
    CVReturn errorCode = CVPixelBufferCreate(kCFAllocatorDefault, image.size.width, image.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}, (id)kCVPixelBufferCGImageCompatibilityKey: @YES}, &pixelBuffer);
    if (pixelBuffer) {
        NSError *error;
        MTIRenderTask *renderTask = [self startTaskToRenderImage:image toCVPixelBuffer:pixelBuffer sRGB:sRGB error:&error];
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

@end
