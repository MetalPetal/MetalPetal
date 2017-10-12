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

@interface MTIMPSProcessingRecipe : NSObject <MTIImagePromise>

@property (nonatomic,strong) MTIMPSKernel *kernel;

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *parameters;

@property (nonatomic,readonly) MTIPixelFormat outputPixelFormat;

@end

@implementation MTIMPSProcessingRecipe
@synthesize dimensions = _dimensions;

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
    
    MPSKernel *kernel = [renderingContext.context kernelStateForKernel:self.kernel pixelFormat:MTIKernelPixelFormatDontCare error:&error];
    
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    [kernel setValuesForKeysWithDictionary:self.parameters];
    
    MTLPixelFormat pixelFormat = MTIPixelFormatValueIsSpecified(self.outputPixelFormat) ? self.outputPixelFormat.value : renderingContext.context.workingPixelFormat;

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;

    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[textureDescriptor newMTITextureDescriptor]];
    
    if (self.inputImages.count == 1) {
        MPSUnaryImageKernel *encoder = (MPSUnaryImageKernel *)kernel;
        [encoder encodeToCommandBuffer:renderingContext.commandBuffer sourceTexture:inputResolutions.firstObject.texture destinationTexture:renderTarget.texture];
    } else if (self.inputImages.count == 2) {
        MPSBinaryImageKernel *encoder = (MPSBinaryImageKernel *)kernel;
        [encoder encodeToCommandBuffer:renderingContext.commandBuffer primaryTexture:inputResolutions.firstObject.texture secondaryTexture:inputResolutions.lastObject.texture destinationTexture:renderTarget.texture];
    } else {
        if (inOutError) {
            *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorMPSKernelInputCountMismatch userInfo:@{}];
        }
        return nil;
    }
    
    for (id<MTIImagePromiseResolution> resolution in inputResolutions) {
        [resolution markAsConsumedBy:self];
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
             outputPixelFormat:(MTIPixelFormat)outputPixelFormat {
    if (self = [super init]) {
        _inputImages = inputImages;
        _kernel = kernel;
        _parameters = parameters;
        _dimensions = outputTextureDimensions;
        _outputPixelFormat = outputPixelFormat;
    }
    return self;
}

@end

@interface MTIMPSKernel ()

@property (nonatomic,copy) MTIMPSKernelBuilder builder;

@end

@implementation MTIMPSKernel

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder {
    if (self = [super init]) {
        _builder = [builder copy];
    }
    return self;
}

- (id)newKernelStateWithContext:(MTIContext *)context pixelFormat:(MTLPixelFormat)pixelFormat error:(NSError * _Nullable __autoreleasing *)error {
    return self.builder(context.device);
}

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions outputPixelFormat:(MTIPixelFormat)outputPixelFormat {
    MTIMPSProcessingRecipe *receipt = [[MTIMPSProcessingRecipe alloc] initWithKernel:self
                                                                         inputImages:images
                                                                          parameters:parameters
                                                             outputTextureDimensions:outputTextureDimensions
                                                                   outputPixelFormat:outputPixelFormat];
    return [[MTIImage alloc] initWithPromise:receipt];
}

@end
