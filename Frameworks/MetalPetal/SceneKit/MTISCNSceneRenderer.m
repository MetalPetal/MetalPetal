//
//  MLARSCNCamera.m
//  MLARSCNCameraDemo
//
//

#if __has_include(<SceneKit/SceneKit.h>)

#import "MTISCNSceneRenderer.h"
#import "MTICVMetalTextureCache.h"
#import "MTICVPixelBufferPool.h"
#import "MTIImage+Promise.h"
#import "MTIImageRenderingContext.h"
#import "MTIContext+Internal.h"
#import "MTITextureDescriptor.h"
#import "MTIImagePromiseDebug.h"
#import "MTIError.h"
#import "MTIImagePromise.h"

//TODO: fix the condition for Apple silicon.
#define MTI_TARGET_SUPPORT_MEMORYLESS_TEXTURE (TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST)

NSString * const MTISCNSceneRendererErrorDomain = @"MTISCNSceneRendererErrorDomain";

__attribute__((objc_subclassing_restricted))
@interface MTISCNSceneImagePromise: NSObject <MTIImagePromise>

@property (nonatomic, readonly) MTLPixelFormat pixelFormat;
@property (nonatomic, readonly) SCNRenderer *renderer;
@property (nonatomic, readonly) CFTimeInterval frameTime;
@property (nonatomic, readonly) CGRect viewport;
@property (nonatomic, readonly) SCNAntialiasingMode antialiasingMode;

@end

@implementation MTISCNSceneImagePromise

@synthesize alphaType = _alphaType;
@synthesize dependencies = _dependencies;
@synthesize dimensions = _dimensions;

- (instancetype)initWithRenderer:(SCNRenderer *)renderer
                antialiasingMode:(SCNAntialiasingMode)antialiasingMode
                        viewport:(CGRect)viewport
                       frameTime:(CFTimeInterval)frameTime
                     pixelFormat:(MTLPixelFormat)pixelFormat
                        isOpaque:(BOOL)opaque {
    if (self = [super init]) {
        _dependencies = @[];
        _dimensions = MTITextureDimensionsMake2DFromCGSize(viewport.size);
        _alphaType = opaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied;
        _pixelFormat = pixelFormat;
        _antialiasingMode = antialiasingMode;
        _renderer = renderer;
        _frameTime = frameTime;
        _viewport = viewport;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (nonnull instancetype)promiseByUpdatingDependencies:(nonnull NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (nullable MTIImagePromiseRenderTarget *)resolveWithContext:(nonnull MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing * _Nullable)error {
#if SCN_ENABLE_METAL
    NSParameterAssert(renderingContext.context.device == self.renderer.device);
    if (renderingContext.context.device != self.renderer.device) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorCrossDeviceRendering, nil);
        }
        return nil;
    }
    
    MTLPixelFormat pixelFormat = renderingContext.context.workingPixelFormat;
    if (_pixelFormat != MTLPixelFormatInvalid) {
        pixelFormat = _pixelFormat;
    }
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:[MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate] error:error];
    if (!renderTarget) {
        return nil;
    }
    
    MTIImagePromiseRenderTarget *multisampleRenderTarget = nil;
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
    NSUInteger sampleCount = 1;
    switch (_antialiasingMode) {
        case SCNAntialiasingModeNone:
            sampleCount = 1;
            break;
        case SCNAntialiasingModeMultisampling2X:
            sampleCount = 2;
            break;
        case SCNAntialiasingModeMultisampling4X:
            sampleCount = 4;
            break;
        #if TARGET_OS_OSX
        case SCNAntialiasingModeMultisampling8X:
            sampleCount = 8;
            break;
        case SCNAntialiasingModeMultisampling16X:
            sampleCount = 16;
            break;
        #endif
        default:
            NSAssert(NO, @"Unsupported SCNAntialiasingMode.");
            break;
    }
    
    if (![renderingContext.context.device supportsTextureSampleCount:sampleCount]) {
        NSAssert(NO, @"The device does not support %@xMSAA",@(sampleCount));
        sampleCount = 1;
    }
    
    if (sampleCount > 1) {
        MTLTextureDescriptor *multisampleTextureDescriptor = [[MTLTextureDescriptor alloc] init];
        multisampleTextureDescriptor.textureType = MTLTextureType2DMultisample;
        multisampleTextureDescriptor.width = _dimensions.width;
        multisampleTextureDescriptor.height = _dimensions.height;
        multisampleTextureDescriptor.depth = _dimensions.depth;
        multisampleTextureDescriptor.usage = MTLTextureUsageRenderTarget;
        multisampleTextureDescriptor.pixelFormat = pixelFormat;
        multisampleTextureDescriptor.sampleCount = sampleCount;
        #if MTI_TARGET_SUPPORT_MEMORYLESS_TEXTURE
        multisampleTextureDescriptor.storageMode = MTLStorageModeMemoryless;
        id<MTLTexture> multisampleTexture = [renderingContext.context.device newTextureWithDescriptor:multisampleTextureDescriptor];
        if (!multisampleTexture) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
            }
            return nil;
        }
        #else
        multisampleTextureDescriptor.storageMode = MTLStorageModePrivate;
        multisampleRenderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:multisampleTextureDescriptor.newMTITextureDescriptor error:error];
        if (!multisampleRenderTarget) {
            return nil;
        }
        id<MTLTexture> multisampleTexture = multisampleRenderTarget.texture;
        #endif
        renderPassDescriptor.colorAttachments[0].texture = multisampleTexture;
        renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionMultisampleResolve;
    } else {
        renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
        
    [_renderer renderAtTime:_frameTime viewport:_viewport commandBuffer:renderingContext.commandBuffer passDescriptor:renderPassDescriptor];
    
    [multisampleRenderTarget releaseTexture];
    
    return renderTarget;
#else
    if (error) {
        *error = [NSError errorWithDomain:MTISCNSceneRendererErrorDomain code:MTISCNSceneRendererErrorSceneKitDoesNotSupportMetal userInfo:nil];
    }
    return nil;
#endif
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:@{@"SCNRenderer": self.renderer, @"frameTime": @(self.frameTime)}];
}

@end

@interface MTISCNSceneRenderer ()

@property (nonatomic,strong) SCNRenderer *renderer;

@property (nonatomic,strong) id<MTLDevice> device;

@property (nonatomic) MTICVMetalTextureCache *textureCache;

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) MTICVPixelBufferPool *pool;

@end

@implementation MTISCNSceneRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        _renderer = [SCNRenderer rendererWithDevice:device options:nil];
        _commandQueue = [_device newCommandQueue];
        _textureCache = [[MTICVMetalTextureCache alloc] initWithDevice:_device cacheAttributes:nil textureAttributes:nil error:nil];
    }
    return self;
}

- (void)setScene:(SCNScene *)scene {
    _renderer.scene = scene;
}

- (SCNScene *)scene {
    return _renderer.scene;
}

- (SCNRenderer *)scnRenderer {
    return _renderer;
}

- (CFTimeInterval)nextFrameTime {
    return _renderer.nextFrameTime;
}

@end

@implementation MTISCNSceneRenderer (MTIImage)

- (MTIImage *)snapshotAtTime:(CFTimeInterval)time viewport:(CGRect)viewport pixelFormat:(MTLPixelFormat)pixelFormat isOpaque:(BOOL)isOpaque {
    NSAssert(_renderer.scene != nil, @"");
    MTISCNSceneImagePromise *promise = [[MTISCNSceneImagePromise alloc] initWithRenderer:_renderer antialiasingMode:_antialiasingMode viewport:viewport frameTime:time pixelFormat:pixelFormat isOpaque:isOpaque];
    MTIImage *image = [[MTIImage alloc] initWithPromise:promise];
    return image;
}

@end

@implementation MTISCNSceneRenderer (CVPixelBuffer)

- (BOOL)renderAtTime:(CFTimeInterval)time viewport:(CGRect)viewport completion:(void (^)(CVPixelBufferRef _Nonnull))completion error:(NSError *__autoreleasing  _Nullable *)error {
    return [self renderAtTime:time viewport:viewport sRGB:NO completion:completion error:error];
}

- (BOOL)renderAtTime:(CFTimeInterval)time viewport:(CGRect)viewport sRGB:(BOOL)writesToSRGBTexture completion:(void (^)(CVPixelBufferRef _Nonnull))completion error:(NSError * _Nullable __autoreleasing *)inOutError {
#if SCN_ENABLE_METAL
    id<MTLCommandQueue> commandQueue = _commandQueue;
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    if (!_pool) {
        NSError *error;
        _pool = [[MTICVPixelBufferPool alloc] initWithPixelBufferWidth:viewport.size.width pixelBufferHeight:viewport.size.height pixelFormatType:kCVPixelFormatType_32BGRA minimumBufferCount:30 error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return NO;
        }
    } else {
        if (!((_pool.pixelBufferWidth == viewport.size.width) && (_pool.pixelBufferHeight == viewport.size.height))) {
            NSError *error;
            _pool = [[MTICVPixelBufferPool alloc] initWithPixelBufferWidth:viewport.size.width pixelBufferHeight:viewport.size.height pixelFormatType:kCVPixelFormatType_32BGRA minimumBufferCount:30 error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return NO;
            }
        }
    }
    
    CVPixelBufferRef pixelBuffer;
    NSError *error = nil;
    pixelBuffer = [_pool newPixelBufferWithAllocationThreshold:30 error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:writesToSRGBTexture ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm  width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageRenderTarget;
    id<MTICVMetalTexture> cvMetalTexture = [_textureCache newTextureWithCVImageBuffer:pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
    NSUInteger sampleCount = 1;
    switch (_antialiasingMode) {
        case SCNAntialiasingModeNone:
            sampleCount = 1;
            break;
        case SCNAntialiasingModeMultisampling2X:
            sampleCount = 2;
            break;
        case SCNAntialiasingModeMultisampling4X:
            sampleCount = 4;
            break;
        #if TARGET_OS_OSX
        case SCNAntialiasingModeMultisampling8X:
            sampleCount = 8;
            break;
        case SCNAntialiasingModeMultisampling16X:
            sampleCount = 16;
            break;
        #endif
        default:
            NSAssert(NO, @"Unsupported SCNAntialiasingMode.");
            break;
    }
    
    if (![_device supportsTextureSampleCount:sampleCount]) {
        NSAssert(NO, @"The device does not support %@xMSAA",@(sampleCount));
        sampleCount = 1;
    }
    
    if (sampleCount > 1) {
        MTLTextureDescriptor *multisampleTextureDescriptor = [textureDescriptor copy];
        multisampleTextureDescriptor.textureType = MTLTextureType2DMultisample;
        multisampleTextureDescriptor.usage = MTLTextureUsageRenderTarget;
        multisampleTextureDescriptor.sampleCount = sampleCount;
        #if MTI_TARGET_SUPPORT_MEMORYLESS_TEXTURE
        multisampleTextureDescriptor.storageMode = MTLStorageModeMemoryless;
        #else
        multisampleTextureDescriptor.storageMode = MTLStorageModePrivate;
        #endif
        id<MTLTexture> multisampleTexture = [_device newTextureWithDescriptor:multisampleTextureDescriptor];
        if (!multisampleTexture) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
            }
            return NO;
        }
        renderPassDescriptor.colorAttachments[0].texture = multisampleTexture;
        renderPassDescriptor.colorAttachments[0].resolveTexture = cvMetalTexture.texture;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionMultisampleResolve;
    } else {
        renderPassDescriptor.colorAttachments[0].texture = cvMetalTexture.texture;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    
    [_renderer renderAtTime:time viewport:viewport commandBuffer:commandBuffer passDescriptor:renderPassDescriptor];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull commandBuffer) {
        completion(pixelBuffer);
        CVPixelBufferRelease(pixelBuffer);
        [self -> _textureCache flushCache];
    }];
    
    [commandBuffer commit];
    [commandBuffer waitUntilScheduled];
    return YES;
#else
    if (inOutError) {
        *inOutError = [NSError errorWithDomain:MTISCNSceneRendererErrorDomain code:MTISCNSceneRendererErrorSceneKitDoesNotSupportMetal userInfo:nil];
    }
    return NO;
#endif
}

@end

#endif
