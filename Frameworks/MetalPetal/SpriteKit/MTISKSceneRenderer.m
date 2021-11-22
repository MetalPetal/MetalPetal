//
//  MTISKSceneRenderer.m
//  MetalPetal
//
//  Created by YuAo on 2020/7/24.
//

#import "MTISKSceneRenderer.h"
#import "MTIImage+Promise.h"
#import "MTIImageRenderingContext.h"
#import "MTIContext+Internal.h"
#import "MTITextureDescriptor.h"
#import "MTIImagePromiseDebug.h"
#import "MTIError.h"
#import "MTIImagePromise.h"

__attribute__((objc_subclassing_restricted))
@interface MTISKSceneImagePromise: NSObject <MTIImagePromise>

@property (nonatomic,readonly) MTLPixelFormat pixelFormat;
@property (nonatomic,readonly) NSTimeInterval frameTime;
@property (nonatomic,readonly) CGRect viewport;

@property (nonatomic,readonly) id<MTLDevice> device;
@property (nonatomic,readonly) SKRenderer *renderer;

@property (nonatomic,readonly) SKScene *scene;

@end

@implementation MTISKSceneImagePromise
@synthesize alphaType = _alphaType;
@synthesize dependencies = _dependencies;
@synthesize dimensions = _dimensions;

- (instancetype)initWithRenderer:(SKRenderer *)renderer
                          device:(id<MTLDevice>)device
                        viewport:(CGRect)viewport
                       frameTime:(NSTimeInterval)frameTime
                     pixelFormat:(MTLPixelFormat)pixelFormat
                        isOpaque:(BOOL)opaque {
    if (self = [super init]) {
        _dependencies = @[];
        
        _renderer = renderer;
        _device = device;
        _scene = nil;
        
        _dimensions = MTITextureDimensionsMake2DFromCGSize(viewport.size);
        _alphaType = opaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied;
        _pixelFormat = pixelFormat;
        _frameTime = frameTime;
        _viewport = viewport;
    }
    return self;
}

- (instancetype)initWithScene:(SKScene *)scene
                     viewport:(CGRect)viewport
                    frameTime:(NSTimeInterval)frameTime
                  pixelFormat:(MTLPixelFormat)pixelFormat
                     isOpaque:(BOOL)opaque {
    if (self = [super init]) {
        _dependencies = @[];
        
        _renderer = nil;
        _device = nil;
        _scene = scene;
        
        _dimensions = MTITextureDimensionsMake2DFromCGSize(viewport.size);
        _alphaType = opaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied;
        _pixelFormat = pixelFormat;
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
    SKRenderer *renderer = nil;
    if (_device && _renderer) {
        NSParameterAssert(renderingContext.context.device == _device);
        if (renderingContext.context.device != _device) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorCrossDeviceRendering, nil);
            }
            return nil;
        }
        renderer = _renderer;
    } else if (_scene) {
        renderer = [SKRenderer rendererWithDevice:renderingContext.context.device];
        renderer.scene = _scene;
    } else {
        NSAssert(NO, @"No render content found.");
        abort();
    }
    
    MTLPixelFormat pixelFormat = renderingContext.context.workingPixelFormat;
    if (_pixelFormat != MTLPixelFormatInvalid) {
        pixelFormat = _pixelFormat;
    }
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:[MTITextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:_dimensions.width height:_dimensions.height mipmapped:NO usage:MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate] error:error];
    if (!renderTarget) {
        return nil;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = renderTarget.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
    MTLTextureDescriptor *depthStencilTextureDescriptor = [[MTLTextureDescriptor alloc] init];
    depthStencilTextureDescriptor.width = renderTarget.texture.width;
    depthStencilTextureDescriptor.height = renderTarget.texture.height;
    depthStencilTextureDescriptor.depth = 1;
    depthStencilTextureDescriptor.pixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    depthStencilTextureDescriptor.usage = MTLTextureUsageRenderTarget;
    
    if (renderingContext.context.isMemorylessTextureSupported) {
        if (@available(macCatalyst 14.0, macOS 11.0, *)) {
            depthStencilTextureDescriptor.storageMode = MTLStorageModeMemoryless;
        } else {
            NSAssert(NO, @"");
        }
    } else {
        depthStencilTextureDescriptor.storageMode = MTLStorageModePrivate;
    }
    
    id<MTLTexture> depthStencilTexture = [renderingContext.context.device newTextureWithDescriptor:depthStencilTextureDescriptor];
    if (!depthStencilTexture) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    
    // Depth render target
    renderPassDescriptor.depthAttachment.texture = depthStencilTexture;
    renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    // Stencil render target
    renderPassDescriptor.stencilAttachment.texture = depthStencilTexture;
    renderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionDontCare;
    
    [renderer updateAtTime:_frameTime];
    [renderer renderWithViewport:_viewport commandBuffer:renderingContext.commandBuffer renderPassDescriptor:renderPassDescriptor];
    
    return renderTarget;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:@{@"SKRenderer": self.renderer, @"frameTime": @(self.frameTime)}];
}

@end

@interface MTISKSceneRenderer ()

@property (nonatomic,strong) SKRenderer *renderer;

@property (nonatomic,strong) id<MTLDevice> device;

@end

@implementation MTISKSceneRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _renderer = [SKRenderer rendererWithDevice:device];
        _device = device;
    }
    return self;
}

- (void)setScene:(SKScene *)scene {
    _renderer.scene = scene;
}

- (SKScene *)scene {
    return _renderer.scene;
}

- (SKRenderer *)skRenderer {
    return _renderer;
}

@end

@implementation MTISKSceneRenderer (MTIImage)

- (id)snapshotAtTime:(NSTimeInterval)time viewport:(CGRect)viewport pixelFormat:(MTLPixelFormat)pixelFormat isOpaque:(BOOL)isOpaque {
    NSAssert(_renderer.scene != nil, @"");
    MTISKSceneImagePromise *promise = [[MTISKSceneImagePromise alloc] initWithRenderer:_renderer device:_device viewport:viewport frameTime:time pixelFormat:pixelFormat isOpaque:isOpaque];
    return [[MTIImage alloc] initWithPromise:promise];
}

@end


@implementation MTIImage (MTISKSceneRenderer)

- (instancetype)initWithSKScene:(SKScene *)scene time:(NSTimeInterval)time viewport:(CGRect)viewport pixelFormat:(MTLPixelFormat)pixelFormat isOpaque:(BOOL)isOpaque {
    MTISKSceneImagePromise *promise = [[MTISKSceneImagePromise alloc] initWithScene:[scene copy] viewport:viewport frameTime:time pixelFormat:pixelFormat isOpaque:isOpaque];
    return [[MTIImage alloc] initWithPromise:promise cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithSKScene:(SKScene *)scene {
    return [self initWithSKScene:scene time:CFAbsoluteTimeGetCurrent() viewport:CGRectMake(0, 0, scene.size.width, scene.size.height) pixelFormat:MTLPixelFormatInvalid isOpaque:NO];
}

@end
