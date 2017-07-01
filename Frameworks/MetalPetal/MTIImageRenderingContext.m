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
}


- (MTIVertices *)verticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } },
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } }
    } count:6];
}

- (void)renderImage:(MTIImage *)image toDrawableWithCallback:(id<MTLDrawable>  _Nonnull (^)(void))drawableCallback renderPassDescriptorCallback:(MTLRenderPassDescriptor * _Nonnull (^)(void))renderPassDescriptorCallback error:(NSError *__autoreleasing  _Nullable *)inOutError {
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
    
    id<MTLDrawable> drawable = drawableCallback();
    MTLRenderPassDescriptor *renderPassDescriptor = renderPassDescriptorCallback();
    
    MTIRenderPipeline *renderPipeline = [renderingContext.context renderPipelineWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat
                                                                                      vertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_vertex"]
                                                                                    fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_fragment"]
                                                                                                         error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return;
    }
    
#warning cache renderPassDescriptor/uniformsBuffer/verticesBuffer
    matrix_float4x4 transform = matrix_identity_float4x4;
    id<MTLBuffer> uniformsBuffer = [renderingContext.context.device newBufferWithBytes:&transform length:sizeof(transform) options:0];
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:uniformsBuffer offset:0 atIndex:1];
    
    [commandEncoder setFragmentTexture:texture atIndex:0];
    id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:image.samplerDescriptor];
    [commandEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    [renderingContext.commandBuffer presentDrawable:drawable];
    
    [renderingContext.commandBuffer commit];

}

@end

