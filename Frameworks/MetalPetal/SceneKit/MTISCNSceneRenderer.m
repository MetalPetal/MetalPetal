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

NSString * const MTISCNSceneRendererErrorDomain = @"MTISCNSceneRendererErrorDomain";

@interface MTISCNSceneImagePromise: NSObject <MTIImagePromise>

@property (nonatomic) MTLPixelFormat pixelFormat;
@property (nonatomic) SCNRenderer *renderer;
@property (nonatomic) CFTimeInterval frameTime;
@property (nonatomic) CGRect viewport;

@end

@implementation MTISCNSceneImagePromise

@synthesize alphaType = _alphaType;
@synthesize dependencies = _dependencies;
@synthesize dimensions = _dimensions;

- (instancetype)initWithRenderer:(SCNRenderer *)renderer
                        viewport:(CGRect)viewport
                       frameTime:(CFTimeInterval)frameTime
                     pixelFormat:(MTLPixelFormat)pixelFormat
                        isOpaque:(BOOL)opaque {
    if (self = [super init]) {
        _dependencies = @[];
        _dimensions = MTITextureDimensionsMake2DFromCGSize(viewport.size);
        _alphaType = opaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied;
        _pixelFormat = pixelFormat;
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
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
    [_renderer renderAtTime:_frameTime viewport:_viewport commandBuffer:renderingContext.commandBuffer passDescriptor:renderPassDescriptor];
    
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
    _scene = scene;
    _renderer.scene = scene;
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
    MTISCNSceneImagePromise *promise = [[MTISCNSceneImagePromise alloc] initWithRenderer:_renderer viewport:viewport frameTime:time pixelFormat:pixelFormat isOpaque:isOpaque];
    MTIImage *image = [[MTIImage alloc] initWithPromise:promise];
    return image;
}

@end

@implementation MTISCNSceneRenderer (CVPixelBuffer)

- (BOOL)renderAtTime:(CFTimeInterval)time viewport:(CGRect)viewport completion:(void (^)(CVPixelBufferRef _Nonnull))completion error:(NSError * _Nullable __autoreleasing *)inOutError {
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
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
    id<MTICVMetalTexture> cvMetalTexture = [_textureCache newTextureWithCVImageBuffer:pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return NO;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = cvMetalTexture.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
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
