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

@interface MTIVertices : NSObject

@property (nonatomic,readonly) MTIVertex *buffer NS_RETURNS_INNER_POINTER;

@property (nonatomic,readonly) NSInteger count;

@end

@implementation MTIVertices

- (instancetype)initWithVertices:(MTIVertex *)vertices count:(NSInteger)count {
    if (self = [super init]) {
        _count = count;
        _buffer = calloc(count, sizeof(MTIVertex));
        memcpy(_buffer, vertices, count * sizeof(MTIVertex));
    }
    return self;
}

- (void)dealloc {
    if (_buffer) {
        free(_buffer);
    }
}

@end

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

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)inOutError {
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
        [inputTextures addObject:[image.promise resolveWithContext:context error:&error]];
    }
    id<MTLFunction> vertextFunction = [context.context functionWithDescriptor:self.vertexFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    id<MTLFunction> fragmentFunction = [context.context functionWithDescriptor:self.fragmentFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    MTIRenderPipelineInfo *renderPipelineInfo = [context.context renderPipelineInfoWithColorAttachmentPixelFormats:self.textureDescriptor.pixelFormat vertexFunction:vertextFunction fragmentFunction:fragmentFunction error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLTexture> renderTarget = [context.context.device newTextureWithDescriptor:[self.textureDescriptor newMTLTextureDescriptor]];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
#warning cache renderPassDescriptor/uniformsBuffer/verticesBuffer
    matrix_float4x4 transform = matrix_identity_float4x4;
    MTIUniforms uniforms = (MTIUniforms){ .modelViewProjectionMatrix = transform };
    id<MTLBuffer> uniformsBuffer = [context.context.device newBufferWithBytes:&uniforms length:sizeof(uniforms) options:0];
    
    MTIVertices *vertices = [self verticesForRect:CGRectMake(-1, -1, 2, 2)];
    id<MTLBuffer> verticesBuffer = [context.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
    
    __auto_type commandEncoder = [context.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:renderPipelineInfo.pipelineState];
    [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:uniformsBuffer offset:0 atIndex:1];
    
    for (NSUInteger index = 0; index < inputTextures.count; index += 1) {
        [commandEncoder setFragmentTexture:inputTextures[index] atIndex:index];
        id<MTLSamplerState> samplerState = [context.context samplerStateWithDescriptor:self.inputImages[index].samplerDescriptor];
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
