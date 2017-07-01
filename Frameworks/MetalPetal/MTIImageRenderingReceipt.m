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
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4];
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
    
#warning use a texture pool
    id<MTLTexture> renderTarget = [renderingContext.context.device newTextureWithDescriptor:[self.textureDescriptor newMTLTextureDescriptor]];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipeline.state];
    
    if (vertices.count * sizeof(MTIVertex) < 4096) {
        //The setVertexBytes:length:atIndex: method is the best option for binding a very small amount (less than 4 KB) of dynamic buffer data to a vertex function. This method avoids the overhead of creating an intermediary MTLBuffer object. Instead, Metal manages a transient buffer for you.
        [commandEncoder setVertexBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) atIndex:0];
    } else {
        #warning cache buffers
        id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
        [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    }
    
    for (NSUInteger index = 0; index < inputTextures.count; index += 1) {
        [commandEncoder setFragmentTexture:inputTextures[index] atIndex:index];
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.inputImages[index].samplerDescriptor];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
    }
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
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
