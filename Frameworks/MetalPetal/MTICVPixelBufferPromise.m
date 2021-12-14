//
//  MTICVPixelBufferPromise.m
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import "MTICVPixelBufferPromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIContext.h"
#import "MTIRenderPipeline.h"
#import "MTIComputePipeline.h"
#import "MTIError.h"
#import "MTIImagePromiseDebug.h"
#import "MTICVMetalTextureCache.h"
#import "MTIContext+Internal.h"
#import "MTIPixelFormat.h"
#import "MTIDefer.h"
#import <simd/simd.h>

static NSString * const MTIColorConversionVertexFunctionName   = @"colorConversionVertex";
static NSString * const MTIColorConversionFragmentFunctionName = @"colorConversionFragment";
static NSString * const MTIColorConversionKernelFunctionName   = @"colorConversion";

static const float MTIYUVColorConversionVertexData[16] =
{
    -1.0, -1.0,  0.0, 1.0,
    1.0, -1.0,  1.0, 1.0,
    -1.0,  1.0,  0.0, 0.0,
    1.0,  1.0,  1.0, 0.0,
};

//Always use "struct X {}; typedef struct X X;" to define a struct, so that the struct can be encoded/archived with NSValue. ref: https://stackoverflow.com/a/12292033/1061004
struct MTIYUVColorConversion {
    matrix_float3x3 matrix;
    vector_float3 offset;
};
typedef struct MTIYUVColorConversion MTIYUVColorConversion;

// BT.601
static const MTIYUVColorConversion MTIYUVColorConversion601 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.392, 2.017, },
        .columns[2] = { 1.596, -0.813, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};

// BT.601 Full Range
static const MTIYUVColorConversion MTIYUVColorConversion601FullRange = {
    .matrix = {
        .columns[0] = { 1.000,  1.000, 1.000, },
        .columns[1] = { 0.000, -0.343, 1.765, },
        .columns[2] = { 1.400, -0.711, 0.000, },
    },
    .offset = { 0.0, -0.5, -0.5 },
};

// BT.709
static const MTIYUVColorConversion MTIYUVColorConversion709 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.213, 2.112, },
        .columns[2] = { 1.793, -0.533, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};

// BT.709 Full Range: vacancy

MTIContextPromiseAssociatedValueTableName const MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable = @"MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable";

// for internal use only
static MTLPixelFormat MTIMTLPixelFormatForCVPixelFormatType(OSType type, BOOL sRGB) {
    switch (type) {
        case kCVPixelFormatType_32BGRA:
            return sRGB ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm;
            
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            return sRGB ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm;
            
        case kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr10BiPlanarFullRange:
            return sRGB ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm;

        case kCVPixelFormatType_32RGBA:
            return sRGB ? MTLPixelFormatRGBA8Unorm_sRGB : MTLPixelFormatRGBA8Unorm;
            
        case kCVPixelFormatType_DisparityFloat16:
        case kCVPixelFormatType_DepthFloat16:
        case kCVPixelFormatType_OneComponent16Half:
            NSCParameterAssert(!sRGB);
            return MTLPixelFormatR16Float;
            
        case kCVPixelFormatType_DisparityFloat32:
        case kCVPixelFormatType_DepthFloat32:
        case kCVPixelFormatType_OneComponent32Float:
            NSCParameterAssert(!sRGB);
            return MTLPixelFormatR32Float;
            
        case kCVPixelFormatType_OneComponent8:
            #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
            return sRGB ? MTLPixelFormatR8Unorm_sRGB : MTLPixelFormatR8Unorm;
            #else
            NSCParameterAssert(!sRGB); //R8Unorm_sRGB texture is not available on macOS.
            return sRGB ? MTLPixelFormatInvalid : MTLPixelFormatR8Unorm;
            #endif
            
        default:
            return MTLPixelFormatInvalid;
    }
}

@interface MTICVPixelBufferPromise ()

@property (nonatomic, strong, readonly) MTITextureDescriptor *coreImageRendererDefaultTextureDescriptor;

@end

@implementation MTICVPixelBufferPromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer options:(nonnull MTICVPixelBufferRenderingOptions *)options alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        NSParameterAssert(pixelBuffer);
        _alphaType = alphaType;
        _renderingAPI = options.renderingAPI;
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _dimensions = (MTITextureDimensions){CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 1};
        _sRGB = options.sRGB;
        _coreImageRendererDefaultTextureDescriptor = [MTITextureDescriptor
                                                      texture2DDescriptorWithPixelFormat:MTIMTLPixelFormatForCVPixelFormatType(CVPixelBufferGetPixelFormatType(pixelBuffer), _sRGB)
                                                      width:CVPixelBufferGetWidth(_pixelBuffer)
                                                      height:CVPixelBufferGetHeight(_pixelBuffer)
                                                      mipmapped:NO
                                                      usage:MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite
                                                      resourceOptions:MTLResourceStorageModePrivate];
    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_pixelBuffer);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (nullable MTIRenderPipeline *)colorConversionRenderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat context:(MTIContext *)context error:(NSError * __autoreleasing *)inOutError {
    
    NSError *error;
    id<MTLFunction> vertexFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionVertexFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionFragmentFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    return [context renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (nullable MTIComputePipeline *)colorConversionComputePipelineWithContext:(MTIContext *)context error:(NSError * __autoreleasing *)inOutError {
    NSError *error;
    id<MTLFunction> computeFunction = [context functionWithDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIColorConversionKernelFunctionName] error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    MTLComputePipelineDescriptor *computePipelineDescriptor = [[MTLComputePipelineDescriptor alloc] init];
    computePipelineDescriptor.computeFunction = computeFunction;
    
    return [context computePipelineWithDescriptor:computePipelineDescriptor error:inOutError];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext_CI:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    if (self.coreImageRendererDefaultTextureDescriptor.pixelFormat == MTLPixelFormatInvalid) {
        NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    NSError *error;
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:self.coreImageRendererDefaultTextureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    CIImage *image = [CIImage imageWithCVPixelBuffer:self.pixelBuffer];
    CGColorSpaceRef colorSpace = nil;
    if (_sRGB) {
        //with sRGB texture CI should write linearRGB values
        colorSpace = nil;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    @MTI_DEFER {
        CGColorSpaceRelease(colorSpace);
    };
    CIRenderDestination *destination = [[CIRenderDestination alloc] initWithMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer];
    destination.colorSpace = colorSpace;
    destination.flipped = YES;
    [renderingContext.context.coreImageContext startTaskToRender:image toDestination:destination error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    return renderTarget;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext_MTI:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(self.pixelBuffer);
    switch (pixelFormatType) {
        case kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr10BiPlanarFullRange: {
            if (renderingContext.context.isYCbCrPixelFormatSupported) {
                MTLPixelFormat pixelFormat = self.sRGB ? MTIPixelFormatYCBCR10_420_2P_sRGB : MTIPixelFormatYCBCR10_420_2P;
                NSError *error = nil;
                MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO];
                textureDescriptor.usage = MTLTextureUsageShaderRead;
                id<MTICVMetalTexture> cvMetalTexture = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:_pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
                if (cvMetalTexture) {
                    [renderingContext.context setValue:cvMetalTexture forPromise:self inTable:MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable];
                } else {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                return [renderingContext.context newRenderTargetWithTexture:cvMetalTexture.texture];
            } else {
                NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
            if (renderingContext.context.isYCbCrPixelFormatSupported) {
                MTLPixelFormat pixelFormat = self.sRGB ? MTIPixelFormatYCBCR8_420_2P_sRGB : MTIPixelFormatYCBCR8_420_2P;
                NSError *error = nil;
                MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO];
                textureDescriptor.usage = MTLTextureUsageShaderRead;
                id<MTICVMetalTexture> cvMetalTexture = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:_pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
                if (cvMetalTexture) {
                    [renderingContext.context setValue:cvMetalTexture forPromise:self inTable:MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable];
                } else {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                return [renderingContext.context newRenderTargetWithTexture:cvMetalTexture.texture];
            } else {
                BOOL isFullYUVRange = (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ? YES : NO);
                
                MTIYUVColorConversion const *preferredConversion = nil;
                CFTypeRef colorAttachments = CVBufferGetAttachment(self.pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
                if (colorAttachments != NULL) {
                    if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        if (isFullYUVRange) {
                            preferredConversion = &MTIYUVColorConversion601FullRange;
                        } else {
                            preferredConversion = &MTIYUVColorConversion601;
                        }
                    } else {
                        preferredConversion = &MTIYUVColorConversion709;
                    }
                } else {
                    if (isFullYUVRange) {
                        preferredConversion = &MTIYUVColorConversion601FullRange;
                    } else {
                        preferredConversion = &MTIYUVColorConversion601;
                    }
                }
                
                NSError *error = nil;
                
                size_t plane0Width = CVPixelBufferGetWidthOfPlane(self.pixelBuffer, 0);
                size_t plane0Height = CVPixelBufferGetHeightOfPlane(self.pixelBuffer, 0);
                MTLTextureDescriptor *yTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:plane0Width height:plane0Height mipmapped:NO];
                yTextureDescriptor.usage = MTLTextureUsageShaderRead;
                id<MTICVMetalTexture> cvMetalTextureY = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:_pixelBuffer textureDescriptor:yTextureDescriptor planeIndex:0 error:&error];
                if (error || !cvMetalTextureY) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                size_t plane1Width = CVPixelBufferGetWidthOfPlane(self.pixelBuffer, 1);
                size_t plane1Height = CVPixelBufferGetHeightOfPlane(self.pixelBuffer, 1);
                MTLTextureDescriptor *uvTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRG8Unorm width:plane1Width height:plane1Height mipmapped:NO];
                uvTextureDescriptor.usage = MTLTextureUsageShaderRead;
                id<MTICVMetalTexture> cvMetalTextureCbCr = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:self.pixelBuffer textureDescriptor:uvTextureDescriptor planeIndex:1 error:&error];
                if (error || !cvMetalTextureCbCr) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                // Render Pipeline
                MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
                MTITextureDescriptor *textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO usage:MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget resourceOptions:MTLResourceStorageModePrivate];
                MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
                renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
                renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionDontCare;
                renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
                
                MTIRenderPipeline *renderPipeline = [self colorConversionRenderPipelineWithColorAttachmentPixelFormat:renderPassDescriptor.colorAttachments[0].texture.pixelFormat context:renderingContext.context error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                
                __auto_type renderCommandEncoder = [renderingContext.commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                [renderCommandEncoder setRenderPipelineState:renderPipeline.state];
                [renderCommandEncoder setVertexBytes:MTIYUVColorConversionVertexData length:16*sizeof(float) atIndex:0];
                [renderCommandEncoder setFragmentTexture:cvMetalTextureY.texture atIndex:0];
                [renderCommandEncoder setFragmentTexture:cvMetalTextureCbCr.texture atIndex:1];
                [renderCommandEncoder setFragmentBytes:preferredConversion length:sizeof(MTIYUVColorConversion) atIndex:0];
                bool convertToLinearRGB = self.sRGB;
                [renderCommandEncoder setFragmentBytes:&convertToLinearRGB length:sizeof(convertToLinearRGB) atIndex:1];
                [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
                [renderCommandEncoder endEncoding];
                
                return renderTarget;
            }
        } break;
        default:{
            MTLPixelFormat pixelFormat = MTIMTLPixelFormatForCVPixelFormatType(CVPixelBufferGetPixelFormatType(self.pixelBuffer), self.sRGB);
            if (pixelFormat == MTLPixelFormatInvalid) {
                NSError *error = MTIErrorCreate(MTIErrorUnsupportedCVPixelBufferFormat, nil);
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            NSError *error = nil;
            MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:CVPixelBufferGetWidth(_pixelBuffer) height:CVPixelBufferGetHeight(_pixelBuffer) mipmapped:NO];
            textureDescriptor.usage = MTLTextureUsageShaderRead;
            id<MTICVMetalTexture> cvMetalTexture = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:_pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
            if (cvMetalTexture) {
                [renderingContext.context setValue:cvMetalTexture forPromise:self inTable:MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable];
            } else {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            
            #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
            //Workaround for #64. See https://github.com/MetalPetal/MetalPetal/issues/64
            if (![renderingContext.context.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1]) {
                NSError *error;
                MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor.newMTITextureDescriptor error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
                id<MTLBlitCommandEncoder> commandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
                if (!commandEncoder) {
                    if (inOutError) {
                        *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
                    }
                    return nil;
                }
                [commandEncoder copyFromTexture:cvMetalTexture.texture sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(cvMetalTexture.texture.width, cvMetalTexture.texture.height, cvMetalTexture.texture.depth) toTexture:renderTarget.texture destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)];
                [commandEncoder endEncoding];
                return renderTarget;
            }
            #endif
            
            return [renderingContext.context newRenderTargetWithTexture:cvMetalTexture.texture];
        } break;
    }
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    if (_renderingAPI == MTICVPixelBufferRenderingAPIMetalPetal && CVPixelBufferGetIOSurface(_pixelBuffer) == NULL) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"[MTICVPixelBufferPromise] Warning once only: CVPixelBuffer is not backed by IOSurface, fallback to use MTICVPixelBufferRenderingAPICoreImage.");
        });
        return [self resolveWithContext_CI:renderingContext error:inOutError];
    }
    switch (self.renderingAPI) {
        case MTICVPixelBufferRenderingAPIMetalPetal:
            return [self resolveWithContext_MTI:renderingContext error:inOutError];
        case MTICVPixelBufferRenderingAPICoreImage:
            return [self resolveWithContext_CI:renderingContext error:inOutError];
        default: {
            NSError *error = MTIErrorCreate(MTIErrorInvalidCVPixelBufferRenderingAPI, nil);
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    }
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:[CIImage imageWithCVPixelBuffer:self.pixelBuffer]];
}

@end


@interface MTICVPixelBufferDirectBridgePromise ()

@property (nonatomic, readonly) CVPixelBufferRef pixelBuffer;
@property (nonatomic, copy, readonly) MTLTextureDescriptor *textureDescriptor;
@property (nonatomic, readonly) NSUInteger planeIndex;

@end

@implementation MTICVPixelBufferDirectBridgePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (void)dealloc {
    CVPixelBufferRelease(_pixelBuffer);
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(NSUInteger)planeIndex textureDescriptor:(MTLTextureDescriptor *)textureDescriptor alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _dimensions = (MTITextureDimensions){
            .width = textureDescriptor.width,
            .height = textureDescriptor.height,
            .depth = textureDescriptor.depth
        };
        _alphaType = alphaType;
        _textureDescriptor = [textureDescriptor copy];
        _planeIndex = planeIndex;
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    }
    return self;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSError *error;
    id<MTICVMetalTexture> cvMetalTexture = [renderingContext.context.coreVideoTextureBridge newTextureWithCVImageBuffer:_pixelBuffer textureDescriptor:self.textureDescriptor planeIndex:self.planeIndex error:&error];
    if (cvMetalTexture) {
        [renderingContext.context setValue:cvMetalTexture forPromise:self inTable:MTIContextCVPixelBufferPromiseCVMetalTextureHolderTable];
    } else {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    return [renderingContext.context newRenderTargetWithTexture:cvMetalTexture.texture];
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:[CIImage imageWithCVPixelBuffer:self.pixelBuffer]];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
