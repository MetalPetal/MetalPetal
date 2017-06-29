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

NSString * const MTIContextErrorDomain = @"MTIContextErrorDomain";

@interface MTIContext()

@property (nonatomic,copy) NSDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic,copy) NSDictionary<MTIFilterFunctionDescriptor *, id<MTLFunction>> *functionCache;

@property (nonatomic,copy) NSDictionary<MTLRenderPipelineDescriptor *, MTIRenderPipeline *> *renderPipelineInfoCache;

@property (nonatomic,copy) NSDictionary<MTISamplerDescriptor *, id<MTLSamplerState>> *samplerStateCache;

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

#pragma mark - Cache

- (id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLLibrary> library = [self.device newLibraryWithFile:URL.path error:error];
    if (library) {
        NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithDictionary:self.libraryCache];
        cache[URL] = library;
        self.libraryCache = cache;
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

- (MTIRenderPipeline *)renderPipelineWithColorAttachmentPixelFormat:(MTLPixelFormat)pixelFormat
                                           vertexFunctionDescriptor:(MTIFilterFunctionDescriptor *)vertexFunctionDescriptor
                                         fragmentFunctionDescriptor:(MTIFilterFunctionDescriptor *)fragmentFunctionDescriptor
                                                              error:(NSError * __autoreleasing *)inOutError {
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexDescriptor = MTIVertexCreateMTLVertexDescriptor();
    
    NSError *error;
    id<MTLFunction> vertextFunction = [self functionWithDescriptor:vertexFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self functionWithDescriptor:fragmentFunctionDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    
    renderPipelineDescriptor.vertexFunction = vertextFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    renderPipelineDescriptor.colorAttachments[0].blendingEnabled = NO;
    
    return [self renderPipelineWithDescriptor:renderPipelineDescriptor error:inOutError];
}

- (MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)renderPipelineDescriptor error:(NSError * __autoreleasing *)inOutError {
    MTIRenderPipeline *cachedState = self.renderPipelineInfoCache[renderPipelineDescriptor];
    if (!cachedState) {
        MTLRenderPipelineReflection *reflection; //get reflection
        NSError *error = nil;
        id<MTLRenderPipelineState> renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
        if (renderPipelineState && !error) {
            MTIRenderPipeline *state = [[MTIRenderPipeline alloc] initWithState:renderPipelineState reflection:reflection];
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

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor {
    id<MTLSamplerState> cachedState = self.samplerStateCache[descriptor];
    if (!cachedState) {
        id<MTLSamplerState> state = [self.device newSamplerStateWithDescriptor:[descriptor newMTLSamplerDescriptor]];
        __auto_type cache = [NSMutableDictionary dictionaryWithDictionary:self.samplerStateCache];
        cache[descriptor] = state;
        self.samplerStateCache = cache;
        cachedState = state;
    }
    return cachedState;
}

@end
