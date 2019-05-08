//
//  MTILibrarySource.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/5/7.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIURLSchemeForLibraryWithSource;

FOUNDATION_EXPORT NSString * const MTILibrarySourceErrorDomain;

typedef NS_ERROR_ENUM(MTILibrarySourceErrorDomain, MTILibrarySourceError) {
    MTILibrarySourceErrorLibraryNotFound = 10001
};

/// MTILibrarySourceRegistration can be used under the situation where it is impossible to use a offline metal compiler. You should avoid using this class as possbile as you can.
@interface MTILibrarySourceRegistration : NSObject

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, strong, readonly, class) MTILibrarySourceRegistration *sharedRegistration;

/// Returns a URL representing the metal library compiled with the `source` code. This URL can be used in `MTIFunctionDescriptor(name:libraryURL:)`.
- (NSURL *)registerLibraryWithSource:(NSString *)source
                      compileOptions:(nullable MTLCompileOptions *)compileOptions NS_SWIFT_NAME(registerLibrary(source:compileOptions:));

- (void)unregisterLibraryWithURL:(NSURL *)url;

@end

@interface MTILibrarySourceRegistration (Internal)

- (nullable id<MTLLibrary>)newLibraryWithURL:(NSURL *)libraryURL device:(id<MTLDevice>)device error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
