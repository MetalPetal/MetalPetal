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
#import "MTIKernel.h"
#import "MTIWeakToStrongObjectsMapTable.h"
#import "MTIError.h"
#import "MTICVMetalTextureCache.h"
#import "MTICVMetalIOSurfaceBridge.h"
#import "MTILock.h"
#import "MTIPixelFormat.h"
#import "MTILibrarySource.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

NSString * const MTIContextDefaultLabel = @"MetalPetal";

@implementation MTIContextOptions

- (instancetype)init {
    if (self = [super init]) {
        _coreImageContextOptions = nil;
        _workingPixelFormat = MTLPixelFormatBGRA8Unorm;
        _enablesRenderGraphOptimization = NO;
        _enablesYCbCrPixelFormatSupport = YES;
        _automaticallyReclaimResources = YES;
        _label = MTIContextDefaultLabel;
        #ifdef SWIFTPM_MODULE_BUNDLE
        _defaultLibraryURL = MTIDefaultLibraryURLForBundle(SWIFTPM_MODULE_BUNDLE);
        #else
        _defaultLibraryURL = MTIDefaultLibraryURLForBundle([NSBundle bundleForClass:self.class]);
        #endif
        _textureLoaderClass = MTIContextOptions.defaultTextureLoaderClass;
        _coreVideoMetalTextureBridgeClass = MTIContextOptions.defaultCoreVideoMetalTextureBridgeClass;
        _texturePoolClass = MTIContextOptions.defaultTexturePoolClass;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTIContextOptions *options = [[MTIContextOptions allocWithZone:zone] init];
    options.coreImageContextOptions = _coreImageContextOptions;
    options.workingPixelFormat = _workingPixelFormat;
    options.enablesRenderGraphOptimization = _enablesRenderGraphOptimization;
    options.automaticallyReclaimResources = _automaticallyReclaimResources;
    options.label = _label;
    options.defaultLibraryURL = _defaultLibraryURL;
    options.textureLoaderClass = _textureLoaderClass;
    options.coreVideoMetalTextureBridgeClass = _coreVideoMetalTextureBridgeClass;
    options.texturePoolClass = _texturePoolClass;
    return options;
}

static Class _defaultTextureLoaderClass = nil;

+ (void)setDefaultTextureLoaderClass:(Class<MTITextureLoader>)defaultTextureLoaderClass {
    _defaultTextureLoaderClass = defaultTextureLoaderClass;
}

+ (Class<MTITextureLoader>)defaultTextureLoaderClass {
    return _defaultTextureLoaderClass ?: MTKTextureLoader.class;
}

static Class _defaultCoreVideoMetalTextureBridgeClass = nil;

+ (void)setDefaultCoreVideoMetalTextureBridgeClass:(Class<MTICVMetalTextureBridging>)defaultCoreVideoMetalTextureBridgeClass {
    _defaultCoreVideoMetalTextureBridgeClass = defaultCoreVideoMetalTextureBridgeClass;
}

+ (Class<MTICVMetalTextureBridging>)defaultCoreVideoMetalTextureBridgeClass {
    if (@available(iOS 11_0, macOS 10_11, *)) {
        return _defaultCoreVideoMetalTextureBridgeClass ?: MTICVMetalIOSurfaceBridge.class;
    } else {
        return _defaultCoreVideoMetalTextureBridgeClass ?: MTICVMetalTextureCache.class;
    }
}

static Class _defaultTexturePoolClass = nil;

+ (void)setDefaultTexturePoolClass:(Class<MTITexturePool>)defaultTexturePoolClass {
    _defaultTexturePoolClass = defaultTexturePoolClass;
}

+ (Class<MTITexturePool>)defaultTexturePoolClass {
    return _defaultTexturePoolClass ?: MTIDeviceTexturePool.class;
}

@end


NSURL * MTIDefaultLibraryURLForBundle(NSBundle *bundle) {
    return [bundle URLForResource:@"default" withExtension:@"metallib"];
}


static BOOL MTIMPSSupportsMTLDevice(id<MTLDevice> device) {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    return MPSSupportsMTLDevice(device);
#endif
}


static void _MTIContextInstancesTracking(void (^action)(NSPointerArray *instances)) {
    static NSPointerArray * _MTIContextAllInstances;
    static id<MTILocking> _MTIContextAllInstancesAccessLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _MTIContextAllInstances = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality];
        _MTIContextAllInstancesAccessLock = MTILockCreate();
    });
    [_MTIContextAllInstancesAccessLock lock];
    action(_MTIContextAllInstances);
    [_MTIContextAllInstancesAccessLock unlock];
}

static void MTIContextMarkInstanceCreation(MTIContext *context) {
    _MTIContextInstancesTracking(^(NSPointerArray *instances){
        [instances addPointer:(__bridge void *)(context)];
        [instances addPointer:nil];
        [instances compact];
    });
}

static void MTIContextEnumerateAllInstances(void (^enumerator)(MTIContext *context)) {
    _MTIContextInstancesTracking(^(NSPointerArray *instances){
        for (MTIContext *context in instances) {
            if (context) {
                enumerator(context);
            }
        }
    });
}

@interface MTIContext()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTIFunctionDescriptor *, id<MTLFunction>> *functionCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTLRenderPipelineDescriptor *, MTIRenderPipeline *> *renderPipelineCache;
@property (nonatomic, strong, readonly) NSMutableDictionary<MTLComputePipelineDescriptor *, MTIComputePipeline *> *computePipelineCache;

@property (nonatomic, strong, readonly) NSMutableDictionary<MTISamplerDescriptor *, id<MTLSamplerState>> *samplerStateCache;

@property (nonatomic, strong, readonly) id<MTITexturePool> texturePool;

@property (nonatomic, strong, readonly) NSMapTable<id<MTIKernel>, id> *kernelStateMap;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, MTIWeakToStrongObjectsMapTable *> *promiseKeyValueTables;
@property (nonatomic, strong, readonly) id<MTILocking> promiseKeyValueTablesLock;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, MTIWeakToStrongObjectsMapTable *> *imageKeyValueTables;
@property (nonatomic, strong, readonly) id<MTILocking> imageKeyValueTablesLock;

@property (nonatomic, strong, readonly) NSMapTable<id<MTIImagePromise>, MTIImagePromiseRenderTarget *> *promiseRenderTargetTable;
@property (nonatomic, strong, readonly) id<MTILocking> promiseRenderTargetTableLock;

@property (nonatomic, strong, readonly) id<MTILocking> renderingLock;

@end

@implementation MTIContext

- (void)dealloc {
    [MTIMemoryWarningObserver removeMemoryWarningHandler:self];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError * __autoreleasing *)inOutError {
    if (self = [super init]) {
        NSParameterAssert(device);
        NSParameterAssert(options);
        
        #if TARGET_OS_SIMULATOR
        if (!MTIContext.enablesSimulatorSupport) {
            NSError *error = MTIErrorCreate(MTIErrorFeatureNotAvailableOnSimulator, @{@"MTIFeatureNotAvailable": @"MTIContext"});
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        #endif
        
        if (!device) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorDeviceNotFound, nil);
            }
            return nil;
        }
        
        NSError *libraryError = nil;
        id<MTLLibrary> defaultLibrary = nil;
        if ([options.defaultLibraryURL.scheme isEqualToString:MTIURLSchemeForLibraryWithSource]) {
            defaultLibrary = [MTILibrarySourceRegistration.sharedRegistration newLibraryWithURL:options.defaultLibraryURL device:device error:&libraryError];
        } else {
            defaultLibrary = [device newLibraryWithFile:options.defaultLibraryURL.path error:&libraryError];
        }
        if (!defaultLibrary || libraryError) {
            if (inOutError) {
                *inOutError = libraryError;
            }
            return nil;
        }
        
        _label = options.label;
        _workingPixelFormat = options.workingPixelFormat;
        _isRenderGraphOptimizationEnabled = options.enablesRenderGraphOptimization;
        _device = device;
        _defaultLibrary = defaultLibrary;
        _coreImageContext = [CIContext contextWithMTLDevice:device options:options.coreImageContextOptions];
        _commandQueue = [device newCommandQueue];
        _commandQueue.label = options.label;
        
        _isMetalPerformanceShadersSupported = MTIMPSSupportsMTLDevice(device);
        _isYCbCrPixelFormatSupported = options.enablesYCbCrPixelFormatSupport && MTIDeviceSupportsYCBCRPixelFormat(device);
        
        _textureLoader = [options.textureLoaderClass newTextureLoaderWithDevice:device];
        NSAssert(_textureLoader != nil, @"Cannot create texture loader.");
        
        _texturePool = [options.texturePoolClass newTexturePoolWithDevice:device];
        _libraryCache = [NSMutableDictionary dictionary];
        _libraryCache[options.defaultLibraryURL] = defaultLibrary;
        _functionCache = [NSMutableDictionary dictionary];
        _renderPipelineCache = [NSMutableDictionary dictionary];
        _computePipelineCache = [NSMutableDictionary dictionary];
        _samplerStateCache = [NSMutableDictionary dictionary];
        _kernelStateMap = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory|NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory capacity:0];

        _promiseKeyValueTables = [NSMutableDictionary dictionary];
        _promiseKeyValueTablesLock = MTILockCreate();

        _imageKeyValueTables = [NSMutableDictionary dictionary];
        _imageKeyValueTablesLock = MTILockCreate();
        
        _promiseRenderTargetTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        _promiseRenderTargetTableLock = MTILockCreate();
        
        _renderingLock = MTILockCreate();
        
        NSError *coreVideoMetalTextureBridgeError = nil;
        _coreVideoTextureBridge = [options.coreVideoMetalTextureBridgeClass newCoreVideoMetalTextureBridgeWithDevice:device error:&coreVideoMetalTextureBridgeError];
        if (coreVideoMetalTextureBridgeError) {
            if (inOutError) {
                *inOutError = coreVideoMetalTextureBridgeError;
            }
            return nil;
        }
        
        if (options.automaticallyReclaimResources) {
            [MTIMemoryWarningObserver addMemoryWarningHandler:self];
        }
        
        MTIContextMarkInstanceCreation(self);
    }
    return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError * __autoreleasing *)error {
    return [self initWithDevice:device options:[[MTIContextOptions alloc] init] error:error];
}

+ (BOOL)defaultMetalDeviceSupportsMPS {
    static BOOL _defaultMetalDeviceSupportsMPS;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        _defaultMetalDeviceSupportsMPS = MTIMPSSupportsMTLDevice(device);
    });
    return _defaultMetalDeviceSupportsMPS;
}

- (void)reclaimResources {
    [_texturePool flush];
    
    [_coreVideoTextureBridge flushCache];
    
    [_coreImageContext clearCaches];
    
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

+ (void)enumerateAllInstances:(void (^)(MTIContext * _Nonnull))enumerator {
    MTIContextEnumerateAllInstances(enumerator);
}

@end

#pragma mark - MTIImagePromiseRenderTarget

@interface MTIImagePromiseRenderTarget ()

@property (nonatomic,strong) id<MTLTexture> nonreusableTexture;

@property (nonatomic,strong) MTIReusableTexture *reusableTexture;

@end

@implementation MTIImagePromiseRenderTarget

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _nonreusableTexture = texture;
        _reusableTexture = nil;
    }
    return self;
}

- (instancetype)initWithResuableTexture:(MTIReusableTexture *)texture {
    if (self = [super init]) {
        _nonreusableTexture = nil;
        _reusableTexture = texture;
    }
    return self;
}

- (id<MTLTexture>)texture {
    if (_nonreusableTexture) {
        return _nonreusableTexture;
    }
    return _reusableTexture.texture;
}

- (BOOL)retainTexture {
    if (_nonreusableTexture) {
        return YES;
    }
    return [_reusableTexture retainTexture];
}

- (void)releaseTexture {
    [_reusableTexture releaseTexture];
}

@end

#pragma mark - MTIContext Internal

@implementation MTIContext (Internal)

#pragma mark - Render Target

- (MTIImagePromiseRenderTarget *)newRenderTargetWithTexture:(id<MTLTexture>)texture {
    return [[MTIImagePromiseRenderTarget alloc] initWithTexture:texture];
}

- (MTIImagePromiseRenderTarget *)newRenderTargetWithResuableTextureDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError * __autoreleasing *)error {
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

- (id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError * __autoreleasing *)error {
    NSAssert([self.renderingLock tryLock] == NO, MTIContextRenderingLockNotLockedErrorDescription);
    id<MTLLibrary> library = self.libraryCache[URL];
    if (!library) {
        if ([URL.scheme isEqualToString:MTIURLSchemeForLibraryWithSource]) {
            library = [MTILibrarySourceRegistration.sharedRegistration newLibraryWithURL:URL device:self.device error:error];
        } else {
            library = [self.device newLibraryWithFile:URL.path error:error];
        }
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
        
        NSString *functionName = descriptor.name;
        #if TARGET_OS_SIMULATOR
        for (NSString *name in library.functionNames) {
            if ([name hasSuffix:[@"::" stringByAppendingString:descriptor.name]]) {
                functionName = name;
                break;
            }
        }
        #endif
        
        if (descriptor.constantValues) {
            NSError *error = nil;
            cachedFunction = [library newFunctionWithName:functionName constantValues:descriptor.constantValues error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
        } else {
            cachedFunction = [library newFunctionWithName:functionName];
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

- (MTIComputePipeline *)computePipelineWithDescriptor:(MTLComputePipelineDescriptor *)computePipelineDescriptor error:(NSError * __autoreleasing *)inOutError {
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

- (id)kernelStateForKernel:(id<MTIKernel>)kernel configuration:(id<MTIKernelConfiguration>)configuration error:(NSError * __autoreleasing *)error {
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

- (nullable id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor error:(NSError * __autoreleasing *)error {
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

- (void)setRenderTarget:(MTIImagePromiseRenderTarget *)renderTarget forPromise:(id<MTIImagePromise>)promise {
    NSParameterAssert(promise);
    NSParameterAssert(renderTarget);
    [_promiseRenderTargetTableLock lock];
    [_promiseRenderTargetTable setObject:renderTarget forKey:promise];
    [_promiseRenderTargetTableLock unlock];
}

- (MTIImagePromiseRenderTarget *)renderTargetForPromise:(id<MTIImagePromise>)promise {
    NSParameterAssert(promise);
    [_promiseRenderTargetTableLock lock];
    MTIImagePromiseRenderTarget *renderTarget = [_promiseRenderTargetTable objectForKey:promise];
    [_promiseRenderTargetTableLock unlock];
    return renderTarget;
}

@end

@implementation MTIContext (MemoryWarningHandling)

- (void)handleMemoryWarning {
    [self reclaimResources];
}

@end

@implementation MTIContext (SimulatorSupport)

static BOOL _enablesSimulatorSupport = YES;

+ (void)setEnablesSimulatorSupport:(BOOL)enablesSimulatorSupport {
    _enablesSimulatorSupport = enablesSimulatorSupport;
}

+ (BOOL)enablesSimulatorSupport {
    return _enablesSimulatorSupport;
}

@end
