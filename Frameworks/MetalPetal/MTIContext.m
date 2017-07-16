//
//  MTIContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIContext.h"
#import "MTIVertex.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTITexturePool.h"
#import "MTIKernel.h"

NSString * const MTIContextErrorDomain = @"MTIContextErrorDomain";

@implementation MTIContextOptions

- (instancetype)init {
    if (self = [super init]) {
        _coreImageContextOptions = @{kCIContextWorkingColorSpace: CFBridgingRelease(CGColorSpaceCreateDeviceRGB())};
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTIContextOptions *options = [[MTIContextOptions allocWithZone:zone] init];
    options.coreImageContextOptions = self.coreImageContextOptions;
    return options;
}

@end


@interface MTIContext()

@property (nonatomic,strong,readonly) NSMutableDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic,strong,readonly) NSMutableDictionary<MTIFilterFunctionDescriptor *, id<MTLFunction>> *functionCache;

@property (nonatomic,strong,readonly) NSMutableDictionary<MTLRenderPipelineDescriptor *, MTIRenderPipeline *> *renderPipelineCache;

@property (nonatomic,strong,readonly) NSMutableDictionary<MTISamplerDescriptor *, id<MTLSamplerState>> *samplerStateCache;

@property (nonatomic,strong,readonly) NSMapTable<id<MTIKernel>, id> *kernelStateMap;

@end

@implementation MTIContext

- (void)dealloc {
#if COREVIDEO_SUPPORTS_METAL
    if (_coreVideoTextureCache) {
        CVMetalTextureCacheFlush(_coreVideoTextureCache, 0);
        CFRelease(_coreVideoTextureCache);
    }
#endif
}

- (instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError * _Nullable __autoreleasing *)error {
    if (self = [super init]) {
        _device = device;
        NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"default" withExtension:@"metallib"];
        _defaultLibrary = [device newLibraryWithFile:url.path error:error];
        if (!_defaultLibrary) {
            return nil;
        }
        _coreImageContext = [CIContext contextWithMTLDevice:device options:options.coreImageContextOptions];
        _commandQueue = [device newCommandQueue];
        _textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        _texturePool = [[MTITexturePool alloc] initWithDevice:device];
        _libraryCache = [NSMutableDictionary dictionary];
        _functionCache = [NSMutableDictionary dictionary];
        _renderPipelineCache = [NSMutableDictionary dictionary];
        _samplerStateCache = [NSMutableDictionary dictionary];
        _kernelStateMap = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory|NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory capacity:0];
#if COREVIDEO_SUPPORTS_METAL
        CVReturn __unused coreVideoTextureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.device, NULL, &_coreVideoTextureCache);
        NSAssert(coreVideoTextureCacheError == kCVReturnSuccess, @"");
#endif
    }
    return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithDevice:device options:nil error:error];
}

#pragma mark - Cache

- (id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLLibrary> library = self.libraryCache[URL];
    if (!library) {
        library = [self.device newLibraryWithFile:URL.path error:error];
        if (library) {
            self.libraryCache[URL] = library;
        }
    }
    return library;
}

- (id<MTLFunction>)functionWithDescriptor:(MTIFilterFunctionDescriptor *)descriptor error:(NSError * __autoreleasing *)inOutError {
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
        cachedFunction = [library newFunctionWithName:descriptor.name];
        if (!cachedFunction) {
            if (inOutError) {
                *inOutError = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorFunctionNotFound userInfo:@{}];
            }
            return nil;
        }
        self.functionCache[descriptor] = cachedFunction;
    }
    return cachedFunction;
}

- (MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)renderPipelineDescriptor error:(NSError * __autoreleasing *)inOutError {
    MTLRenderPipelineDescriptor *key = [renderPipelineDescriptor copy];
    MTIRenderPipeline *renderPipeline = self.renderPipelineCache[key];
    if (!renderPipeline) {
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

- (id)kernelStateForKernel:(id<MTIKernel>)kernel error:(NSError * _Nullable __autoreleasing *)error {
    id cachedState = [self.kernelStateMap objectForKey:kernel];
    if (!cachedState) {
        cachedState = [kernel newKernelStateWithContext:self error:error];
        if (cachedState) {
            [self.kernelStateMap setObject:cachedState forKey:kernel];
        }
    }
    return cachedState;
}

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor {
    id<MTLSamplerState> state = self.samplerStateCache[descriptor];
    if (!state) {
        state = [self.device newSamplerStateWithDescriptor:[descriptor newMTLSamplerDescriptor]];
        self.samplerStateCache[descriptor] = state;
    }
    return state;
}

@end
