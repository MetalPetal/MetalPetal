//
//  MTIRenderPipelineKernel.m
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import "MTIRenderPipelineKernel.h"
#import "MTIContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImagePromise.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTIImage+Promise.h"
#import "MTIVector.h"
#import "MTIVector+Private.h"

@interface MTIImageRenderingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,strong,readonly) MTIRenderPipelineKernel *kernel;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *functionParameters;

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

@end

@implementation MTIImageRenderingRecipe
@synthesize dimensions = _dimensions;

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

- (NSArray<MTIImage *> *)dependencies {
    return self.inputImages;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSError *error = nil;
    NSMutableArray<id<MTIImagePromiseResolution>> *inputResolutions = [NSMutableArray array];
    for (MTIImage *image in self.inputImages) {
        id<MTIImagePromiseResolution> resolution = [renderingContext resolutionForImage:image error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        NSAssert(resolution != nil, @"");
        [inputResolutions addObject:resolution];
    }
    
    MTIRenderPipeline *renderPipeline = [renderingContext.context kernelStateForKernel:self.kernel error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
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
        id<MTLBuffer> verticesBuffer = [renderingContext.context.device newBufferWithBytes:vertices.buffer length:vertices.count * sizeof(MTIVertex) options:0];
        [commandEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];
    }
    
    for (NSUInteger index = 0; index < inputResolutions.count; index += 1) {
        [commandEncoder setFragmentTexture:inputResolutions[index].texture atIndex:index];
        id<MTLSamplerState> samplerState = [renderingContext.context samplerStateWithDescriptor:self.inputImages[index].samplerDescriptor];
        [commandEncoder setFragmentSamplerState:samplerState atIndex:index];
    }
    
    //encode parameters
    if (self.functionParameters.count > 0) {
        MTIEncodeArgumentsWithEncoder(renderPipeline.reflection.vertexArguments, self.functionParameters, commandEncoder, MTLFunctionTypeVertex, &error);
        MTIEncodeArgumentsWithEncoder(renderPipeline.reflection.fragmentArguments, self.functionParameters, commandEncoder, MTLFunctionTypeFragment, &error);
        if (inOutError && error != nil) {
            *inOutError = error;
        }
    }
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertices.count];
    [commandEncoder endEncoding];
    
    for (id<MTIImagePromiseResolution> resolution in inputResolutions) {
        [resolution markAsConsumedBy:self];
    }
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIRenderPipelineKernel *)kernel
                   inputImages:(NSArray<MTIImage *> *)inputImages
            functionParameters:(NSDictionary<NSString *,id> *)functionParameters
       outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _functionParameters = functionParameters;
        _textureDescriptor = [outputTextureDescriptor newMTITextureDescriptor];
        _dimensions = (MTITextureDimensions){outputTextureDescriptor.width, outputTextureDescriptor.height, outputTextureDescriptor.depth};
    }
    return self;
}

@end

@interface MTIRenderPipelineKernel ()

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *vertexFunctionDescriptor;
@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptor;
@property (nonatomic,copy,readonly) MTLVertexDescriptor *vertexDescriptor;
@property (nonatomic,copy,readonly) MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor;

@end

@implementation MTIRenderPipelineKernel

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor colorAttachmentPixelFormat:(MTLPixelFormat)colorAttachmentPixelFormat {
    MTLRenderPipelineColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.pixelFormat = colorAttachmentPixelFormat;
    colorAttachmentDescriptor.blendingEnabled = NO;
    return [self initWithVertexFunctionDescriptor:vertexFunctionDescriptor
                       fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                 vertexDescriptor:nil
                        colorAttachmentDescriptor:colorAttachmentDescriptor];
}

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor {
    if (self = [super init]) {
        _vertexFunctionDescriptor = [vertexFunctionDescriptor copy];
        _fragmentFunctionDescriptor = [fragmentFunctionDescriptor copy];
        _vertexDescriptor = [vertexDescriptor copy];
        _colorAttachmentDescriptor = [colorAttachmentDescriptor copy];
    }
    return self;
}

- (MTLPixelFormat)pixelFormat {
    return self.colorAttachmentDescriptor.pixelFormat;
}

- (MTIRenderPipeline *)newKernelStateWithContext:(MTIContext *)context error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor;
    
    NSError *error;
    id<MTLFunction> vertextFunction = [context functionWithDescriptor:self.vertexFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:self.fragmentFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    renderPipelineDescriptor.vertexFunction = vertextFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0] = self.colorAttachmentDescriptor;
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (MTIImage *)applyToInputImages:(NSArray *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    NSParameterAssert(outputTextureDescriptor.pixelFormat == self.colorAttachmentDescriptor.pixelFormat);
    MTIImageRenderingRecipe *receipt = [[MTIImageRenderingRecipe alloc] initWithKernel:self
                                                                           inputImages:images
                                                                    functionParameters:parameters
                                                               outputTextureDescriptor:outputTextureDescriptor];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
