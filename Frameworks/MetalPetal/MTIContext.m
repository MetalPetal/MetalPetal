//
//  MTIContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIContext.h"

@interface MTIRenderPipelineStateOptions : NSObject

@end

@implementation MTIRenderPipelineStateOptions

@end

@interface MTIContext()

@property (nonatomic,copy) NSDictionary<NSURL *, id<MTLLibrary>> *libraryCache;

@property (nonatomic,copy) NSDictionary<NSString *, id<MTLRenderPipelineState>> *renderPipelineStateCache;

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

- (id<MTLRenderPipelineState>)renderPipelineStateWithColorAttachmentCount:(NSInteger)count
                                                             pixelFormats:(const MTLPixelFormat[])pixelFormats
                                                           vertexFunction:(id<MTLFunction>)vertexFunction
                                                         fragmentFunction:(id<MTLFunction>)fragmentFunction {
    MTLRenderPipelineReflection *reflection; //get reflection
    NSError *error;
    MTLRenderPipelineDescriptor *descriptor;
    [self.device newRenderPipelineStateWithDescriptor:descriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
    return nil;
}

@end
