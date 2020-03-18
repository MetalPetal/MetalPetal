//
//  MTICLAHEFilter.m
//  Pods
//
//  Created by YuAo on 13/10/2017.
//

#import "MTICLAHEFilter.h"
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
#import "MTIVector+SIMD.h"
#import "MTIError.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

NSInteger const MTICLAHEHistogramBinCount = 256;

MTICLAHESize MTICLAHESizeMake(NSUInteger width, NSUInteger height) {
    return (MTICLAHESize){.width = width, .height = height };
}

@interface MTICLAHELUTKernelState: NSObject

@property (nonatomic,strong,readonly) MPSImageHistogram *histogramKernel;
@property (nonatomic,strong,readonly) MTIComputePipeline *LUTGeneratingPipeline;

@end

@implementation MTICLAHELUTKernelState

- (instancetype)initWithHistogramKernel:(MPSImageHistogram *)histogramKernel LUTGeneratingPipeline:(MTIComputePipeline *)LUTGeneratingPipeline {
    if (self = [super init]) {
        NSParameterAssert(histogramKernel);
        NSParameterAssert(LUTGeneratingPipeline);
        _histogramKernel = histogramKernel;
        _LUTGeneratingPipeline = LUTGeneratingPipeline;
    }
    return self;
}

@end

@interface MTICLAHELUTKernel: NSObject <MTIKernel>

@end

@interface MTICLAHELUTRecipe: NSObject <MTIImagePromise>

@property (nonatomic,strong,readonly) MTICLAHELUTKernel *kernel;
@property (nonatomic,readonly,strong) MTIImage *inputLightnessImage;
@property (nonatomic,readonly) NSInteger clipLimitValue;
@property (nonatomic,readonly) MTICLAHESize tileGridSize;
@property (nonatomic,readonly) MTICLAHESize tileSize;
@property (nonatomic,readonly) NSUInteger numberOfLUTs;
@property (nonatomic,readonly) float clipLimit;

@end

@implementation MTICLAHELUTRecipe

- (instancetype)initWithKernel:(MTICLAHELUTKernel *)kernel
           inputLightnessImage:(MTIImage *)inputLightnessImage
                     clipLimit:(float)clipLimit
                  tileGridSize:(MTICLAHESize)tileGridSize {
    if (self = [super init]) {
        NSParameterAssert((NSInteger)inputLightnessImage.size.width % tileGridSize.width == 0 && (NSInteger)inputLightnessImage.size.height % tileGridSize.height == 0);
        _kernel = kernel;
        _tileGridSize = tileGridSize;
        _inputLightnessImage = inputLightnessImage;
        _tileSize = MTICLAHESizeMake(inputLightnessImage.size.width/tileGridSize.width, inputLightnessImage.size.height/tileGridSize.height);
        _clipLimit = clipLimit;
        _clipLimitValue = MAX((NSInteger)(clipLimit * _tileSize.width * _tileSize.height / MTICLAHEHistogramBinCount), 1);
        _numberOfLUTs = tileGridSize.width * tileGridSize.height;
    }
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[self.inputLightnessImage];
}

- (MTITextureDimensions)dimensions {
    return (MTITextureDimensions){.width = MTICLAHEHistogramBinCount, .height = self.numberOfLUTs, .depth = 1};
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSParameterAssert(self.inputLightnessImage.alphaType == MTIAlphaTypeAlphaIsOne);
    
    NSError *error = nil;
    id<MTLTexture> inputLightnessImageTexture = [renderingContext resolvedTextureForImage:self.inputLightnessImage];
    
    MTICLAHELUTKernelState *kernelState = [renderingContext.context kernelStateForKernel:self.kernel configuration:nil error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:MTICLAHEHistogramBinCount height:self.numberOfLUTs mipmapped:NO usage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    //May need to get a copy
    MPSImageHistogram *histogramKernel = kernelState.histogramKernel;
    
    //todo: Optimize buffer alloc here
    size_t histogramSize = [histogramKernel histogramSizeForSourceFormat:inputLightnessImageTexture.pixelFormat];
    id<MTLBuffer> histogramBuffer = [renderingContext.context.device newBufferWithLength:histogramSize * self.numberOfLUTs options:MTLResourceStorageModePrivate];
    
    for (NSUInteger tileIndex = 0; tileIndex < self.numberOfLUTs; tileIndex += 1) {
        NSInteger colum = tileIndex % self.tileGridSize.width;
        NSInteger row = tileIndex / self.tileGridSize.width;
        histogramKernel.clipRectSource = MTLRegionMake2D(colum * self.tileSize.width, row * self.tileSize.height, self.tileSize.width, self.tileSize.height);
        [histogramKernel encodeToCommandBuffer:renderingContext.commandBuffer
                                 sourceTexture:inputLightnessImageTexture
                                     histogram:histogramBuffer
                               histogramOffset:tileIndex * histogramSize];
    }
    
    MTICLAHELUTGeneratorInputParameters parameters;
    parameters.histogramBins = (uint)MTICLAHEHistogramBinCount;
    parameters.clipLimit = (uint)self.clipLimitValue;
    parameters.totalPixelCountPerTile = (uint)(self.tileSize.width * self.tileSize.height);
    parameters.numberOfLUTs = (uint)self.numberOfLUTs;
    
    __auto_type commandEncoder = [renderingContext.commandBuffer computeCommandEncoder];
    
    if (!commandEncoder) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
        }
        return nil;
    }
    
    [commandEncoder setComputePipelineState:kernelState.LUTGeneratingPipeline.state];
    [commandEncoder setBuffer:histogramBuffer offset:0 atIndex:0];
    [commandEncoder setBytes:&parameters length:sizeof(parameters) atIndex:1];
    [commandEncoder setTexture:renderTarget.texture atIndex:0];
    
    NSUInteger w = kernelState.LUTGeneratingPipeline.state.threadExecutionWidth;
    MTLSize threadsPerThreadgroup = MTLSizeMake(w, 1, 1);
    MTLSize threadgroupsPerGrid = MTLSizeMake((self.numberOfLUTs + w - 1) / w, 1, 1);
    [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    [commandEncoder endEncoding];
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (MTIAlphaType)alphaType {
    return MTIAlphaTypeAlphaIsOne;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 1);
    return [[MTICLAHELUTRecipe alloc] initWithKernel:self.kernel inputLightnessImage:dependencies.firstObject clipLimit:self.clipLimit tileGridSize:self.tileGridSize];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:@{@"clipLimit": @(self.clipLimit),
                                                                                                                                      @"tileGridSize": @[@(self.tileSize.width),@(self.tileSize.height)]
                                                                                                                                      }];
}

@end

@implementation MTICLAHELUTKernel

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * __autoreleasing *)inOutError {
    if (!context.isMetalPerformanceShadersSupported) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorMPSKernelNotSupported, nil);
        }
        return nil;
    }
    
    MPSImageHistogramInfo info;
    info.numberOfHistogramEntries = MTICLAHEHistogramBinCount;
    info.minPixelValue = (vector_float4){0,0,0,0};
    info.maxPixelValue = (vector_float4){1,1,1,1};
    info.histogramForAlpha = NO;
    MPSImageHistogram *histogram = [[MPSImageHistogram alloc] initWithDevice:context.device histogramInfo:&info];
    histogram.zeroHistogram = NO;
    
    MTLComputePipelineDescriptor *computePipelineDescriptor = [[MTLComputePipelineDescriptor alloc] init];
    NSError *error;
    id<MTLFunction> computeFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"CLAHEGenerateLUT"] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    computePipelineDescriptor.computeFunction = computeFunction;
    MTIComputePipeline *computePipeline = [context computePipelineWithDescriptor:computePipelineDescriptor error:inOutError];
    return [[MTICLAHELUTKernelState alloc] initWithHistogramKernel:histogram LUTGeneratingPipeline:computePipeline];
}

@end


@implementation MTICLAHEFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init {
    if (self = [super init]) {
        _clipLimit = 2.0;
        _tileGridSize = MTICLAHESizeMake(8, 8);
    }
    return self;
}

+ (MTICLAHELUTKernel *)LUTGeneratorKernel {
    static MTICLAHELUTKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTICLAHELUTKernel alloc] init];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)RGB2LightnessKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"CLAHERGB2Lightness"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:[[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypeNonPremultiplied), @(MTIAlphaTypeAlphaIsOne)] outputAlphaType:MTIAlphaTypeAlphaIsOne]];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)CLAHELookupKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"CLAHEColorLookup"]];
    });
    return kernel;
}


- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    MTLSamplerDescriptor *samplerDescriptor = [self.inputImage.samplerDescriptor newMTLSamplerDescriptor];
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeMirrorRepeat;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeMirrorRepeat;
    samplerDescriptor.rAddressMode = MTLSamplerAddressModeMirrorRepeat;
    MTIImage *inputImageForLUT = [self.inputImage imageWithSamplerDescriptor:[samplerDescriptor newMTISamplerDescriptor]];
    
    NSInteger dY = (self.tileGridSize.height - ((NSInteger)self.inputImage.size.height % self.tileGridSize.height)) % self.tileGridSize.height;
    NSInteger dX = (self.tileGridSize.width - ((NSInteger)self.inputImage.size.width % self.tileGridSize.width)) % self.tileGridSize.width;
    
    MTITextureDimensions lightnessTextureDimensions = MTITextureDimensionsMake2DFromCGSize(CGSizeMake(self.inputImage.size.width + dX, self.inputImage.size.height + dY));
    MTIVector *lightnessImageScale = [MTIVector vectorWithFloat2:(simd_float2){(self.inputImage.size.width + dX)/self.inputImage.size.width, (self.inputImage.size.height + dY)/self.inputImage.size.height}];
    
    MTIImage *lightnessImage = [MTICLAHEFilter.RGB2LightnessKernel applyToInputImages:@[inputImageForLUT]
                                                                           parameters:@{@"scale": lightnessImageScale}
                                                              outputTextureDimensions:lightnessTextureDimensions
                                                                    outputPixelFormat:MTLPixelFormatR8Unorm];
    MTIImage *lutImage = [[MTIImage alloc] initWithPromise:[[MTICLAHELUTRecipe alloc] initWithKernel:MTICLAHEFilter.LUTGeneratorKernel
                                                                                 inputLightnessImage:lightnessImage
                                                                                           clipLimit:self.clipLimit
                                                                                        tileGridSize:self.tileGridSize]];
    MTIVector *tileGridSize = [MTIVector vectorWithFloat2:(simd_float2){self.tileGridSize.width, self.tileGridSize.height}];
    MTIImage *outputImage = [MTICLAHEFilter.CLAHELookupKernel applyToInputImages:@[self.inputImage, lutImage]
                                                                      parameters:@{@"tileGridSize": tileGridSize}
                                                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                                                               outputPixelFormat:self.outputPixelFormat];
    return outputImage;
}

@end
