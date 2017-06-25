//
//  MTIFilter.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFilter.h"
#import "MTIStructs.h"
#import "MTIImageRenderingContext.h"

@interface MTIFilter ()

//@property (nonatomic,copy) MTLVertexDescriptor *vertexDescriptor;

@property (nonatomic,copy) MTLRenderPipelineDescriptor *renderPipelineDescriptor;

@property (nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic,strong) id<MTLSamplerState> samplerState;

@property (nonatomic,strong) id<MTLFunction> vertexFunction;
@property (nonatomic,strong) id<MTLFunction> fragmentFunction;

@end

@implementation MTIFilter

- (instancetype)init {
    if (self = [super init]) {
        
        
    }
    return self;
}

- (id<MTLLibrary>)library {
    return nil;
}

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

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [self outputImageWithInputImages:@[self.inputImage]];
}

- (MTIImage *)outputImageWithInputImages:(NSArray<MTIImage *> *)images {
    return nil;
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

@end
