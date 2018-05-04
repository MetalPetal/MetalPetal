//
//  MTIContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIContext.h"
#import "MTIContext+Internal.h"
#import "MTIVertex.h"
#import "MTIFunctionDescriptor.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTIComputePipeline.h"
#import "MTITexturePool.h"
#import "MTIKernel.h"
#import "MTIWeakToStrongObjectsMapTable.h"
#import "MTIError.h"
#import "MTICVMetalTextureCache.h"
#import "MTILock.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@implementation MTIContextOptions

- (instancetype)init {
    if (self = [super init]) {
        _coreImageContextOptions = @{};
        _workingPixelFormat = MTLPixelFormatBGRA8Unorm;
        _enablesRenderGraphOptimization = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTIContextOptions *options = [[MTIContextOptions allocWithZone:zone] init];
    options.coreImageContextOptions = _coreImageContextOptions;
    options.workingPixelFormat = _workingPixelFormat;
    options.enablesRenderGraphOptimization = _enablesRenderGraphOptimization;
    return options;
}

@end

NSURL * MTIDefaultLibraryURLForBundle(NSBundle *bundle) {
    return [bundle URLForResource:@"default" withExtension:@"metallib"];
}

@interface MTIContext()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTIFunctionDescriptor *, id<MTLFunction>> *functionCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTLRenderPipelineDescriptor *, MTIRenderPipeline *> *renderPipelineCache;
@property (nonatomic, strong, readonly) NSMutableDictionary<MTLComputePipelineDescriptor *, MTIComputePipeline *> *computePipelineCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTISamplerDescriptor *, id<MTLSamplerState>> *samplerStateCache;

@property (nonatomic, strong, readonly) MTITexturePool *texturePool;

@property (nonatomic, strong, readonly) NSMapTable<id<MTIKernel>, id> *kernelStateMap;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, MTIWeakToStrongObjectsMapTable *> *promiseKeyValueTables;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, MTIWeakToStrongObjectsMapTable *> *imageKeyValueTables;

@property (nonatomic, strong, readonly) id<MTILocking> renderingLock;
@property (nonatomic, strong, readonly) id<MTILocking> imageKeyValueTablesLock;
@property (nonatomic, strong, readonly) id<MTILocking> promiseKeyValueTablesLock;

@end

@implementation MTIContext

- (instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError * _Nullable __autoreleasing *)inOutError {
    if (self = [super init]) {
        NSParameterAssert(device != nil);
        if (!device) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorDeviceNotFound, nil);
            }
            return nil;
        }
        
        NSError *libraryError = nil;
        NSURL *url = MTIDefaultLibraryURLForBundle([NSBundle bundleForClass:self.class]);
        id<MTLLibrary> defaultLibrary = [device newLibraryWithFile:url.path error:&libraryError];
        if (!defaultLibrary || libraryError) {
            if (inOutError) {
                *inOutError = libraryError;
            }
            return nil;
        }
        
        _workingPixelFormat = options.workingPixelFormat;
        _isRenderGraphOptimizationEnabled = options.enablesRenderGraphOptimization;
        _device = device;
        _defaultLibrary = defaultLibrary;
        _coreImageContext = [CIContext contextWithMTLDevice:device options:options.coreImageContextOptions];
        _commandQueue = [device newCommandQueue];
        _commandQueue.label = @"MetalPetal";
        
        _isMetalPerformanceShadersSupported = MPSSupportsMTLDevice(device);
        
        _textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        _texturePool = [[MTITexturePool alloc] initWithDevice:device];
        _libraryCache = [NSMutableDictionary dictionary];
        _functionCache = [NSMutableDictionary dictionary];
        _renderPipelineCache = [NSMutableDictionary dictionary];
        _computePipelineCache = [NSMutableDictionary dictionary];
        _samplerStateCache = [NSMutableDictionary dictionary];
        _kernelStateMap = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory|NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory capacity:0];
        _promiseKeyValueTables = [NSMutableDictionary dictionary];
        _imageKeyValueTables = [NSMutableDictionary dictionary];
        
        NSError *coreVideoTextureCacheError = nil;
        _coreVideoTextureCache = [[MTICVMetalTextureCache alloc] initWithDevice:device cacheAttributes:nil textureAttributes:nil error:&coreVideoTextureCacheError];
        if (coreVideoTextureCacheError || _coreVideoTextureCache == nil) {
            if (inOutError) {
                *inOutError = coreVideoTextureCacheError;
            }
            return nil;
        }
        
        _renderingLock = MTILockCreate();
        _promiseKeyValueTablesLock = MTILockCreate();
        _imageKeyValueTablesLock = MTILockCreate();
    }
    return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithDevice:device options:[[MTIContextOptions alloc] init] error:error];
}

+ (BOOL)defaultMetalDeviceSupportsMPS {
    static BOOL _defaultMetalDeviceSupportsMPS;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        _defaultMetalDeviceSupportsMPS = MPSSupportsMTLDevice(device);
    });
    return _defaultMetalDeviceSupportsMPS;
}

- (void)reclaimResources {
    [_texturePool flush];
    
    [_imageKeyValueTablesLock lock];
    for (NSString *key in _imageKeyValueTables) {
        [_imageKeyValueTables[key] compact];
    }
    [_imageKeyValueTablesLock unlock];
    
    [_promiseKeyValueTablesLock lock];
    for (NSString *key in _promiseKeyValueTables) {
        [_promiseKeyValueTables[key] compact];
    }
    [_promiseKeyValueTablesLock unlock];
}

- (NSUInteger)idleResourceSize {
    return self.texturePool.idleResourceSize;
}

- (NSUInteger)idleResourceCount {
    return self.texturePool.idleResourceCount;
}

@end

#pragma mark - MTIImagePromiseRenderTarget

@interface MTIImagePromiseRenderTarget ()

@property (nonatomic,strong) id<MTLTexture> nonreusableTexture;

@property (nonatomic,strong) MTIReusableTexture *resuableTexture;

@end

@implementation MTIImagePromiseRenderTarget

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _nonreusableTexture = texture;
        _resuableTexture = nil;
    }
    return self;
}

- (instancetype)initWithResuableTexture:(MTIReusableTexture *)texture {
    if (self = [super init]) {
        _nonreusableTexture = nil;
        _resuableTexture = texture;
    }
    return self;
}

- (id<MTLTexture>)texture {
    if (_nonreusableTexture) {
        return _nonreusableTexture;
    }
    return _resuableTexture.texture;
}

- (BOOL)retainTexture {
    if (_nonreusableTexture) {
        return YES;
    }
    return [_resuableTexture retainTexture];
}

- (void)releaseTexture {
    [_resuableTexture releaseTexture];
}

@end

#pragma mark - MTIContext Internal

@implementation MTIContext (Internal)

#pragma mark - Render Target

- (MTIImagePromiseRenderTarget *)newRenderTargetWithTexture:(id<MTLTexture>)texture {
    return [[MTIImagePromiseRenderTarget alloc] initWithTexture:texture];
}

- (MTIImagePromiseRenderTarget *)newRenderTargetWithResuableTextureDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    MTIReusableTexture *texture = [self.texturePool newTextureWithDescriptor:textureDescriptor error:error];
    if (!texture) {
        return nil;
    }
    return [[MTIImagePromiseRenderTarget alloc] initWithResuableTexture:texture];
}

#pragma mark - Lock

- (void)lockForRendering {
    [_renderingLock lock];
}

- (void)unlockForRendering {
    [_renderingLock unlock];
}

#pragma mark - Cache

static NSString * const MTIContextRenderingLockNotLockedErrorDescription = @"Context is peformaning a render-releated operation without aquiring the renderingLock.";

- (id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError * _Nullable __autoreleasing *)error {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    id<MTLLibrary> library = self.libraryCache[URL];
    if (!library) {
        library = [self.device newLibraryWithFile:URL.path error:error];
        if (library) {
            self.libraryCache[URL] = library;
        }
    }
    return library;
}

- (id<MTLFunction>)functionWithDescriptor:(MTIFunctionDescriptor *)descriptor error:(NSError * __autoreleasing *)inOutError {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    id<MTLFunction> cachedFunction = self.functionCache[descriptor];
    if (!cachedFunction) {
        NSError *error = nil;
        id<MTLLibrary> library = self.defaultLibrary;
        if (descriptor.libraryURL) {
            library = [self libraryWithURL:descriptor.libraryURL error:&error];
        }
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        
        if (@available(iOS 10.0, *)) {
            if (descriptor.constantValues) {
                NSError *error = nil;
                cachedFunction = [library newFunctionWithName:descriptor.name constantValues:descriptor.constantValues error:&error];
                if (error) {
                    if (inOutError) {
                        *inOutError = error;
                    }
                    return nil;
                }
            } else {
                cachedFunction = [library newFunctionWithName:descriptor.name];
            }
        } else {
            cachedFunction = [library newFunctionWithName:descriptor.name];
        }
        
        if (!cachedFunction) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFunctionNotFound, @{@"MTIFunctionDescriptor": descriptor});
            }
            return nil;
        }
        self.functionCache[descriptor] = cachedFunction;
    }
    return cachedFunction;
}

- (MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)renderPipelineDescriptor error:(NSError * __autoreleasing *)inOutError {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    MTIRenderPipeline *renderPipeline = self.renderPipelineCache[renderPipelineDescriptor];
    if (!renderPipeline) {
        MTLRenderPipelineDescriptor *key = [renderPipelineDescriptor copy];
        MTLRenderPipelineReflection *reflection; //get reflection
        NSError *error = nil;
        id<MTLRenderPipelineState> renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
        if (renderPipelineState && !error) {
            renderPipeline = [[MTIRenderPipeline alloc] initWithState:renderPipelineState reflection:reflection];
            self.renderPipelineCache[key] = renderPipeline;
        } else {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    }
    return renderPipeline;
}

- (MTIComputePipeline *)computePipelineWithDescriptor:(MTLComputePipelineDescriptor *)computePipelineDescriptor error:(NSError * _Nullable __autoreleasing *)inOutError {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    MTIComputePipeline *computePipeline = self.computePipelineCache[computePipelineDescriptor];
    if (!computePipeline) {
        MTLComputePipelineDescriptor *key = [computePipelineDescriptor copy];
        MTLComputePipelineReflection *reflection; //get reflection
        NSError *error = nil;
        id<MTLComputePipelineState> computePipelineState = [self.device newComputePipelineStateWithDescriptor:computePipelineDescriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
        if (computePipelineState && !error) {
            computePipeline = [[MTIComputePipeline alloc] initWithState:computePipelineState reflection:reflection];
            self.computePipelineCache[key] = computePipeline;
        } else {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    }
    return computePipeline;
}

- (id)kernelStateForKernel:(id<MTIKernel>)kernel configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * _Nullable __autoreleasing *)error {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    NSMutableDictionary *states = [self.kernelStateMap objectForKey:kernel];
    id<NSCopying> cacheKey = configuration.identifier ?: [NSNull null];
    id cachedState = states[cacheKey];
    if (!cachedState) {
        cachedState = [kernel newKernelStateWithContext:self configuration:configuration error:error];
        if (cachedState) {
            if (!states) {
                states = [NSMutableDictionary dictionary];
                [self.kernelStateMap setObject:states forKey:kernel];
            }
            states[cacheKey] = cachedState;
        }
    }
    return cachedState;
}

- (nullable id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor error:(NSError **)error {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    id<MTLSamplerState> state = self.samplerStateCache[descriptor];
    if (!state) {
        state = [self.device newSamplerStateWithDescriptor:[descriptor newMTLSamplerDescriptor]];
        if (!state) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorFailedToCreateSamplerState, nil);
            }
            return nil;
        }
        self.samplerStateCache[descriptor] = state;
    }
    return state;
}

- (id)valueForPromise:(id<MTIImagePromise>)promise inTable:(MTIContextPromiseAssociatedValueTableName)tableName {
    [_promiseKeyValueTablesLock lock];
    id value = [self.promiseKeyValueTables[tableName] objectForKey:promise];
    [_promiseKeyValueTablesLock unlock];
    return value;
}

- (void)setValue:(id)value forPromise:(id<MTIImagePromise>)promise inTable:(MTIContextPromiseAssociatedValueTableName)tableName {
    [_promiseKeyValueTablesLock lock];
    MTIWeakToStrongObjectsMapTable *table = self.promiseKeyValueTables[tableName];
    if (!table) {
        table = [[MTIWeakToStrongObjectsMapTable alloc] init];
        self.promiseKeyValueTables[tableName] = table;
    }
    [table setObject:value forKey:promise];
    [_promiseKeyValueTablesLock unlock];
}

- (id)valueForImage:(MTIImage *)image inTable:(MTIContextImageAssociatedValueTableName)tableName {
    [_imageKeyValueTablesLock lock];
    id value = [self.imageKeyValueTables[tableName] objectForKey:image];
    [_imageKeyValueTablesLock unlock];
    return value;
}

- (void)setValue:(id)value forImage:(MTIImage *)image inTable:(MTIContextImageAssociatedValueTableName)tableName {
    [_imageKeyValueTablesLock lock];
    MTIWeakToStrongObjectsMapTable *table = self.imageKeyValueTables[tableName];
    if (!table) {
        table = [[MTIWeakToStrongObjectsMapTable alloc] init];
        self.imageKeyValueTables[tableName] = table;
    }
    [table setObject:value forKey:image];
    [_imageKeyValueTablesLock unlock];
}

@end
