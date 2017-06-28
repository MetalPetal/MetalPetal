//
//  MTIContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIContext.h"
#import "MTIStructs.h"
#import "MTIFilterFunctionDescriptor.h"

@implementation MTIRenderPipelineInfo

- (instancetype)initWithState:(id<MTLRenderPipelineState>)state reflection:(MTLRenderPipelineReflection *)reflection {
    if (self = [super init]) {
        _pipelineState = state;
        _pipelineReflection = reflection;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

NSString * const MTIContextErrorDomain = @"MTIContextErrorDomain";

@interface MTIContext()

@property (nonatomic,copy) NSDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic,copy) NSDictionary<MTIFilterFunctionDescriptor *, id<MTLFunction>> *functionCache;

@property (nonatomic,copy) NSDictionary<MTLRenderPipelineDescriptor *, MTIRenderPipelineInfo *> *renderPipelineInfoCache;

@property (nonatomic,copy) NSDictionary<MTLSamplerDescriptor *, id<MTLSamplerState>> *samplerStateCache;

@end

@implementation MTIContext

- (void)dealloc {
    if (_coreVideoTextureCache) {
        CVMetalTextureCacheFlush(_coreVideoTextureCache, 0);
        CFRelease(_coreVideoTextureCache);
    }
}

- (instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (self = [super init]) {
        _device = device;
        _defaultLibrary = [device newDefaultLibraryWithBundle:[NSBundle bundleForClass:self.class] error:error];
        if (!_defaultLibrary) {
            return nil;
        }
        _coreImageContext = [CIContext contextWithMTLDevice:device options:@{kCIContextWorkingColorSpace: CFBridgingRelease(CGColorSpaceCreateDeviceRGB())}];
        _commandQueue = [device newCommandQueue];
        _textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        CVReturn __unused coreVideoTextureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.device, NULL, &_coreVideoTextureCache);
        NSAssert(coreVideoTextureCacheError == kCVReturnSuccess, @"");
    }
    return self;
}

- (id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLLibrary> library = [self.device newLibraryWithFile:URL.path error:error];
    if (library) {
        NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithDictionary:self.libraryCache];
        cache[URL] = library;
        self.libraryCache = cache;
    }
    return library;
}

- (id<MTLFunction>)functionWithDescriptor:(MTIFilterFunctionDescriptor *)descriptor error:(NSError * _Nullable __autoreleasing *)inOutError {
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
        id<MTLFunction> function = [library newFunctionWithName:descriptor.name];
        if (!function) {
            if (inOutError) {
                *inOutError = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorFunctionNotFound userInfo:@{}];
            }
            return nil;
        }
        __auto_type cache = [NSMutableDictionary dictionaryWithDictionary:self.libraryCache];
        cache[descriptor] = function;
        self.libraryCache = cache;
        cachedFunction = function;
    }
    return cachedFunction;
}

- (MTIRenderPipelineInfo *)renderPipelineInfoWithColorAttachmentPixelFormats:(MTLPixelFormat)pixelFormat
                                                              vertexFunction:(id<MTLFunction>)vertexFunction
                                                            fragmentFunction:(id<MTLFunction>)fragmentFunction
                                                                       error:(NSError * _Nullable __autoreleasing * _Nullable)inOutError {
    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    
    vertexDescriptor.attributes[1].offset = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.layouts[0].stride = sizeof(MTIVertex);
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor;
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    renderPipelineDescriptor.colorAttachments[0].blendingEnabled = NO;
    
    MTIRenderPipelineInfo *cachedState = self.renderPipelineInfoCache[renderPipelineDescriptor];
    if (!cachedState) {
        MTLRenderPipelineReflection *reflection; //get reflection
        NSError *error = nil;
        id<MTLRenderPipelineState> renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
        if (renderPipelineState && !error) {
            MTIRenderPipelineInfo *state = [[MTIRenderPipelineInfo alloc] initWithState:renderPipelineState reflection:reflection];
            __auto_type cache = [NSMutableDictionary dictionaryWithDictionary:self.renderPipelineInfoCache];
            cache[renderPipelineDescriptor] = state;
            self.renderPipelineInfoCache = cache;
            cachedState = state;
        } else {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    }
    return cachedState;
}

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTLSamplerDescriptor *)descriptor {
    id<MTLSamplerState> cachedState = self.samplerStateCache[descriptor];
    if (!cachedState) {
        id<MTLSamplerState> state = [self.device newSamplerStateWithDescriptor:descriptor];
        __auto_type cache = [NSMutableDictionary dictionaryWithDictionary:self.samplerStateCache];
        cache[descriptor] = state;
        self.samplerStateCache = cache;
        cachedState = state;
    }
    return cachedState;
}

@end
