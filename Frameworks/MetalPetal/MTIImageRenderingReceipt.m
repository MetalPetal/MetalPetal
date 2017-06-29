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
#import "MTIStructs.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTITextureDescriptor.h"

@implementation MTIImageRenderingReceiptBuilder

@end

@implementation MTIImageRenderingReceipt

- (MTIVertices *)verticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        {.x = l, .y = t, .z = 0, .w = 1, .u = 0, .v = 1},
        {.x = l, .y = b, .z = 0, .w = 1, .u = 0, .v = 0},
        {.x = r, .y = b, .z = 0, .w = 1, .u = 1, .v = 0},
        {.x = l, .y = t, .z = 0, .w = 1, .u = 0, .v = 1},
        {.x = r, .y = b, .z = 0, .w = 1, .u = 1, .v = 0},
        {.x = r, .y = t, .z = 0, .w = 1, .u = 1, .v = 1},
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
    id<MTLFunction> vertextFunction = [renderingContext.context functionWithDescriptor:self.vertexFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    id<MTLFunction> fragmentFunction = [renderingContext.context functionWithDescriptor:self.fragmentFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    MTIRenderPipelineInfo *renderPipelineInfo = [renderingContext.context renderPipelineInfoWithColorAttachmentPixelFormats:self.textureDescriptor.pixelFormat vertexFunction:vertextFunction fragmentFunction:fragmentFunction error:&error];
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
    MTIUniforms uniforms = (MTIUniforms){ .modelViewProjectionMatrix = transform };
    id<MTLBuffer> uniformsBuffer = [renderingContext.context.device newBufferWithBytes:&uniforms length:sizeof(uniforms) options:0];
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
    
    __auto_type commandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipelineInfo.pipelineState];
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
