//
//  MTIImageRenderingReceipt.m
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import "MTIImageRenderingReceipt.h"
#import "MTIImage.h"
#import "MTIContext.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"

@implementation MTIImageRenderingReceiptBuilder

@end

@implementation MTIImageRenderingReceipt

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

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSError *error = nil;
    NSMutableArray<id<MTLTexture>> *inputTextures = [NSMutableArray array];
    for (MTIImage *image in self.inputImages) {
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
#warning fetch resolve result from cache
        [inputTextures addObject:[image.promise resolveWithContext:renderingContext error:&error]];
    }
    
    MTIRenderPipeline *renderPipeline = [renderingContext.context renderPipelineWithColorAttachmentPixelFormat:self.textureDescriptor.pixelFormat
                                                                                      vertexFunctionDescriptor:self.vertexFunctionDescriptor
                                                                                    fragmentFunctionDescriptor:self.fragmentFunctionDescriptor
                                                                                                         error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLTexture> renderTarget = [renderingContext.context.device newTextureWithDescriptor:[self.textureDescriptor newMTLTextureDescriptor]];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
#warning cache renderPassDescriptor/uniformsBuffer/verticesBuffer
    matrix_float4x4 transform = matrix_identity_float4x4;
    id<MTLBuffer> uniformsBuffer = [renderingContext.context.device newBufferWithBytes:&transform length:sizeof(transform) options:0];
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:uniformsBuffer offset:0 atIndex:1];
    
    for (NSUInteger index = 0; index < inputTextures.count; index += 1) {
        [commandEncoder setFragmentTexture:inputTextures[index] atIndex:index];
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.inputImages[index].samplerDescriptor];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
    }
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithBuilder:(MTIImageRenderingReceiptBuilder *)builder {
    if (self = [super init]) {
        _inputImages = builder.inputImages;
        _vertexFunctionDescriptor = builder.vertexFunctionDescriptor;
        _fragmentFunctionDescriptor = builder.fragmentFunctionDescriptor;
        _fragmentFunctionParameters = builder.fragmentFunctionParameters;
        _textureDescriptor = [builder.textureDescriptor newMTITextureDescriptor];
    }
    return self;
}

@end
