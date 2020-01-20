//
//  MTILibrarySource.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/5/7.
//

#import "MTILibrarySource.h"
#import "MTILock.h"

NSString * const MTIURLSchemeForLibraryWithSource = @"mti.library-source";

NSString * const MTILibrarySourceErrorDomain = @"MTILibrarySourceErrorDomain";

static NSURL * MTIURLForLibrarySource(NSString *identifier) {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = MTIURLSchemeForLibraryWithSource;
    components.host = @"shared";
    components.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"id" value:identifier]];
    return [components URL];
}

@interface MTILibrarySource : NSObject

@property (nonatomic, copy, nullable) MTLCompileOptions *compileOptions;

@property (nonatomic, copy) NSString *source;

@end

@implementation MTILibrarySource

- (instancetype)initWithSource:(NSString *)source compileOptions:(nullable MTLCompileOptions *)compileOptions {
    if (self = [super init]) {
        _source = [source copy];
        _compileOptions = [compileOptions copy];
    }
    return self;
}

@end

@interface MTILibrarySourceRegistration ()

@property (nonatomic, strong) NSMutableDictionary<NSURL *, MTILibrarySource *> *sources;

@property (nonatomic, strong) id<MTILocking> lock;

@end

@implementation MTILibrarySourceRegistration

- (instancetype)initForSharedInstance {
    if (self = [super init]) {
        _sources = [NSMutableDictionary dictionary];
        _lock = MTILockCreate();
    }
    return self;
}

+ (MTILibrarySourceRegistration *)sharedRegistration {
    static MTILibrarySourceRegistration *_sharedRegistration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedRegistration = [[MTILibrarySourceRegistration alloc] initForSharedInstance];
    });
    return _sharedRegistration;
}

- (NSURL *)registerLibraryWithSource:(NSString *)source compileOptions:(nullable MTLCompileOptions *)compileOptions {
    NSString *identifier = [NSUUID UUID].UUIDString;
    NSURL *URL = MTIURLForLibrarySource(identifier);
    MTILibrarySource *librarySource = [[MTILibrarySource alloc] initWithSource:source compileOptions:compileOptions];
    [_lock lock];
    _sources[URL] = librarySource;
    [_lock unlock];
    return URL;
}

- (void)unregisterLibraryWithURL:(NSURL *)url {
    [_lock lock];
    [_sources removeObjectForKey:url];
    [_lock unlock];
}

@end

@implementation MTILibrarySourceRegistration (Internal)

- (id<MTLLibrary>)newLibraryWithURL:(NSURL *)libraryURL device:(id<MTLDevice>)device error:(NSError * _Nullable __autoreleasing *)error {
    NSParameterAssert([libraryURL.scheme isEqualToString:MTIURLSchemeForLibraryWithSource]);
    [_lock lock];
    MTILibrarySource *librarySource = _sources[libraryURL];
    [_lock unlock];
    if (!librarySource) {
        if (error) {
            *error = [NSError errorWithDomain:MTILibrarySourceErrorDomain code:MTILibrarySourceErrorLibraryNotFound userInfo:nil];
        }
        return nil;
    }
    return [device newLibraryWithSource:librarySource.source options:librarySource.compileOptions error:error];
}

@end
