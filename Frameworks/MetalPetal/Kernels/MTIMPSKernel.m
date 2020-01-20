//
//  MTIMPSKernel.m
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import "MTIMPSKernel.h"
#import "MTIImage+Promise.h"
#import "MTIContext.h"
#import "MTITextureDescriptor.h"
#import "MTIImageRenderingContext.h"
#import "MTIError.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"

@interface MTIMPSProcessingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,strong) MTIMPSKernel *kernel;

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *parameters;

@property (nonatomic,readonly) MTLPixelFormat outputPixelFormat;

@end

@implementation MTIMPSProcessingRecipe
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (NSArray<MTIImage *> *)dependencies {
    return self.inputImages;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSError *error = nil;
    
    //May need to get a copy
    MPSKernel *kernel = [renderingContext.context kernelStateForKernel:self.kernel configuration:nil error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    [kernel setValuesForKeysWithDictionary:self.parameters];
    
    MTLPixelFormat pixelFormat = (self.outputPixelFormat == MTIPixelFormatUnspecified) ? renderingContext.context.workingPixelFormat : self.outputPixelFormat;
    
    MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    if (self.inputImages.count == 1) {
        id<MTLTexture> texture = [renderingContext resolvedTextureForImage:self.inputImages[0]];
        MPSUnaryImageKernel *encoder = (MPSUnaryImageKernel *)kernel;
        [encoder encodeToCommandBuffer:renderingContext.commandBuffer sourceTexture:texture destinationTexture:renderTarget.texture];
    } else if (self.inputImages.count == 2) {
        id<MTLTexture> texture0 = [renderingContext resolvedTextureForImage:self.inputImages[0]];
        id<MTLTexture> texture1 = [renderingContext resolvedTextureForImage:self.inputImages[1]];
        MPSBinaryImageKernel *encoder = (MPSBinaryImageKernel *)kernel;
        [encoder encodeToCommandBuffer:renderingContext.commandBuffer primaryTexture:texture0 secondaryTexture:texture1 destinationTexture:renderTarget.texture];
    } else {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorMPSKernelInputCountMismatch, nil);
        }
        return nil;
    }
    
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithKernel:(MTIMPSKernel *)kernel
                   inputImages:(NSArray<MTIImage *> *)inputImages
                    parameters:(NSDictionary<NSString *,id> *)parameters
       outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
             outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        NSParameterAssert({
            /* Alpha Type Assert */
            BOOL canAcceptAlphaType = YES;
            for (MTIImage *image in inputImages) {
                if (![kernel.alphaTypeHandlingRule canAcceptAlphaType:image.alphaType]) {
                    canAcceptAlphaType = NO;
                    break;
                }
            }
            canAcceptAlphaType;
        });
        _inputImages = inputImages;
        _kernel = kernel;
        _parameters = parameters;
        _dimensions = outputTextureDimensions;
        _outputPixelFormat = outputPixelFormat;
        _alphaType = [kernel.alphaTypeHandlingRule outputAlphaTypeForInputImages:inputImages];
    }
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == self.dependencies.count);
    return [[MTIMPSProcessingRecipe alloc] initWithKernel:self.kernel inputImages:dependencies parameters:self.parameters outputTextureDimensions:self.dimensions outputPixelFormat:self.outputPixelFormat];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeProcessor content:self.parameters];
}

@end

@interface MTIMPSKernel ()

@property (nonatomic,copy) MTIMPSKernelBuilder builder;

@end

@implementation MTIMPSKernel

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder {
    return [self initWithMPSKernelBuilder:builder alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
}

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder alphaTypeHandlingRule:(MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    if (self = [super init]) {
        _builder = [builder copy];
        _alphaTypeHandlingRule = alphaTypeHandlingRule;
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * __autoreleasing *)error {
    if (!context.isMetalPerformanceShadersSupported) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorMPSKernelNotSupported, nil);
        }
        return nil;
    }
    return self.builder(context.device);
}

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    MTIMPSProcessingRecipe *receipt = [[MTIMPSProcessingRecipe alloc] initWithKernel:self
                                                                         inputImages:images
                                                                          parameters:parameters
                                                             outputTextureDimensions:outputTextureDimensions
                                                                   outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
