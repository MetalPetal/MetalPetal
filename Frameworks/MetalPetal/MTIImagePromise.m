//
//  MTIImagePromise.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIImagePromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIContext.h"

@implementation MTIImageRenderingReceiptBuilder

@end

@implementation MTIImageRenderingReceipt

/*
- (MTLRenderPipelineDescriptor *)createRenderPipelineDescriptor {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexDescriptor = [self createVertexDescriptor];
    renderPipelineDescriptor.vertexFunction = self.vertexFunction;
    renderPipelineDescriptor.fragmentFunction = self.fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    renderPipelineDescriptor.colorAttachments[0].blendingEnabled = NO;
    
    //renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    //renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    
    //renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    //renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    //renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    //renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    return renderPipelineDescriptor;
}

- (MTLVertexDescriptor *)createVertexDescriptor {
    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    
    vertexDescriptor.attributes[1].offset = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.layouts[0].stride = sizeof(MTIVertex);
    return vertexDescriptor;
}


- (void)renderToTexture:(id<MTLTexture>)renderTarget withRenderingContext:(MTIImageRenderingContext *)imageRenderingContext {
    matrix_float4x4 transform = matrix_identity_float4x4;
    __auto_type uniforms = (MTIUniforms){ .modelViewProjectionMatrix = transform };
    __auto_type uniformsBuffer = [imageRenderingContext.context.device newBufferWithBytes:&uniforms length:sizeof(uniforms) options:0];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    __auto_type commandEncoder = [imageRenderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    [commandEncoder setRenderPipelineState:self.renderPipelineState];
    //commandEncoder.setFrontFacing(.counterClockwise)
    //commandEncoder.setCullMode(.back)
    [commandEncoder setVertexBuffer:nil offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:uniformsBuffer offset:0 atIndex:1];
    
    [commandEncoder setFragmentTexture:nil atIndex:0];
    [commandEncoder setFragmentSamplerState:nil atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:2];
    [commandEncoder endEncoding];
    
}
*/

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    //
    return nil;
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
        _outputTextureDescriptor = builder.outputTextureDescriptor;
    }
    return self;
}

@end

@interface MTIPixelBufferImagePromise ()

@property (nonatomic) CVPixelBufferRef pixelBuffer;

@end

@implementation MTIPixelBufferImagePromise

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self = [super init]) {
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_pixelBuffer);
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface MTICGImagePromise ()

@property (nonatomic) CGImageRef image;

@end

@implementation MTICGImagePromise

- (instancetype)initWithCGImage:(CGImageRef)cgImage {
    if (self = [super init]) {
        _image = CGImageRetain(cgImage);
        _outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) mipmapped:NO];
    }
    return self;
}

- (void)dealloc {
    CGImageRelease(_image);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
    id<MTLTexture> texture = [context.context.textureLoader newTextureWithCGImage:self.image options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:error];
    NSLog(@"%@ load time: %@", self, @(CFAbsoluteTimeGetCurrent() - loadStart));
    return texture;
}

@end

