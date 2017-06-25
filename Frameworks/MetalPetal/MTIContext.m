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

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        _defaultLibrary = [device newDefaultLibrary];
        _commandQueue = [device newCommandQueue];
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
    return nil;
}

@end
