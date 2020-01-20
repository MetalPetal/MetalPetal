//
//  MTIMPSHistogramFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/6/11.
//

#import "MTIMPSHistogramFilter.h"
#import "MTIMPSKernel.h"
#import "MTIRenderPipeline.h"
#import "MTIContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage+Promise.h"
#import "MTIImageRenderingContext.h"
#import "MTIRenderPipelineKernel.h"
#import "MTISamplerDescriptor.h"
#import "MTIComputePipeline.h"
#import "MTITextureDescriptor.h"
#import "MTIShaderLib.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"
#import "MTIError.h"
#import "MTIComputePipelineKernel.h"

@interface MTIMPSHistogramRecipe : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTIImage *inputImage;

@property (nonatomic,readonly) MPSImageHistogramInfo histogramInfo;

@property (nonatomic,readonly) MTLRegion sourceRegion;

@end

@implementation MTIMPSHistogramRecipe
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (NSArray<MTIImage *> *)dependencies {
    return @[self.inputImage];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    if (!renderingContext.context.isMetalPerformanceShadersSupported) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorMPSKernelNotSupported, nil);
        }
        return nil;
    }
    
    NSError *error = nil;
    
    NSParameterAssert(self.inputImage.alphaType == MTIAlphaTypeAlphaIsOne || self.inputImage.alphaType == MTIAlphaTypeNonPremultiplied);
    
    id<MTLTexture> inputTexture = [renderingContext resolvedTextureForImage:self.inputImage];
    
    MPSImageHistogramInfo info = self.histogramInfo;
    MPSImageHistogram *kernel = [[MPSImageHistogram alloc] initWithDevice:renderingContext.context.device histogramInfo:&info];
    kernel.clipRectSource = self.sourceRegion;
    kernel.zeroHistogram = YES;
    
    NSUInteger bytesPerComponent = 4;
    NSUInteger bufferSize = _dimensions.width * _dimensions.height * bytesPerComponent;
    NSAssert(bufferSize >= [kernel histogramSizeForSourceFormat:inputTexture.pixelFormat], @"Buffer too small.");
    
    id<MTLBuffer> buffer = [renderingContext.context.device newBufferWithLength:bufferSize options:MTLResourceStorageModePrivate];
    [kernel encodeToCommandBuffer:renderingContext.commandBuffer sourceTexture:inputTexture histogram:buffer histogramOffset:0];
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Uint width:_dimensions.width height:_dimensions.height mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = MTLStorageModePrivate;
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithTexture:[buffer newTextureWithDescriptor:textureDescriptor offset:0 bytesPerRow:self.histogramInfo.numberOfHistogramEntries * bytesPerComponent]];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
                                                 
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithInputImage:(MTIImage *)inputImage
                     histogramInfo:(MPSImageHistogramInfo)histogramInfo
                      sourceRegion:(MTLRegion)sourceRegion {
    if (self = [super init]) {
        _inputImage = inputImage;
        _dimensions = MTITextureDimensionsMake2DFromCGSize(CGSizeMake(histogramInfo.numberOfHistogramEntries, 4));
        _histogramInfo = histogramInfo;
        _sourceRegion = sourceRegion;
        _alphaType = MTIAlphaTypeAlphaIsOne;
    }
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == self.dependencies.count);
    return [[MTIMPSHistogramRecipe alloc] initWithInputImage:dependencies.firstObject histogramInfo:self.histogramInfo sourceRegion:self.sourceRegion];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:@"MPSHistogram"];
}

@end

@interface MTIMPSHistogramFilter ()

@property (nonatomic) MPSImageHistogramInfo histogramInfo;

@end

@implementation MTIMPSHistogramFilter
@synthesize outputPixelFormat = _outputPixelFormat;

- (instancetype)init {
    if (self = [super init]) {
        _outputPixelFormat = MTLPixelFormatR32Uint;
        MPSImageHistogramInfo info = {};
        info.numberOfHistogramEntries = 256;
        info.histogramForAlpha = YES;
        info.minPixelValue = (simd_float4){0.0,0.0,0.0,0.0};
        info.maxPixelValue = (simd_float4){1.0,1.0,1.0,1.0};
        _histogramInfo = info;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    //handle histogram type and scale
    MTIImage *image = self.inputImage;//[MTIRenderPipelineKernel.passthroughRenderPipelineKernel applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(CGSizeMake(self.inputImage.size.width, self.inputImage.size.height)) outputPixelFormat:MTLPixelFormatBGRA8Unorm];
    MTIMPSHistogramRecipe *recipe = [[MTIMPSHistogramRecipe alloc] initWithInputImage:image histogramInfo:self.histogramInfo sourceRegion:MTLRegionMake2D(0, 0, image.size.width, image.size.height)];
    return [[MTIImage alloc] initWithPromise:recipe];
}

@end


@implementation MTIHistogramDisplayFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"histogramDisplay"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
    });
    return kernel;
}

+ (MTIComputePipelineKernel *)histogramMaxKernel {
    static MTIComputePipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIComputePipelineKernel alloc] initWithComputeFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"histogramDisplayFindMax"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    CGSize outputSize = self.outputSize;
    if (outputSize.width <= 0) {
        outputSize.width = self.inputImage.size.width;
    }
    if (outputSize.height <= 0) {
        outputSize.height = self.inputImage.size.width;
    }
    MTIImage *maxValueImage = [MTIHistogramDisplayFilter.histogramMaxKernel applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(CGSizeMake(1, 1)) outputPixelFormat:MTLPixelFormatRGBA32Uint];
    return [MTIHistogramDisplayFilter.kernel applyToInputImages:@[self.inputImage,maxValueImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(outputSize) outputPixelFormat:self.outputPixelFormat];
}

@end
