//
//  MTIImagePromise.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIImagePromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIContext.h"
#import "MTITextureDescriptor.h"
#import "MTIError.h"

@interface MTIImageURLPromise ()

@property (nonatomic,copy) NSURL *URL;

@property (nonatomic,copy) NSDictionary<NSString *, id> *options;

@property (nonatomic,strong) MDLURLTexture *texture;

@end

@implementation MTIImageURLPromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<NSString *, id> *)options {
    if (self = [super init]) {
        _URL = [URL copy];
        _options = [options copy];
        _texture = [[MDLURLTexture alloc] initWithURL:URL name:URL.lastPathComponent];
        _dimensions = (MTITextureDimensions){_texture.dimensions.x, _texture.dimensions.y, 1};
        if (_dimensions.depth * _dimensions.height * _dimensions.width == 0) {
            return nil;
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLTexture> texture;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        texture = [renderingContext.context.textureLoader newTextureWithMDLTexture:self.texture options:self.options error:error];
    } else {
        texture = [renderingContext.context.textureLoader newTextureWithContentsOfURL:self.URL options:self.options error:error];
    }
    if (!texture) {
        if (error) {
            *error = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorFailedToLoadTexture userInfo:@{}];
        }
        return nil;
    }
    return [renderingContext.context newRenderTargetWithTexture:texture];
}

@end

@interface MTICGImagePromise ()

@property (nonatomic) CGImageRef image;

@property (nonatomic,copy) NSDictionary<NSString *, id> *options;

@end

@implementation MTICGImagePromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<NSString *,id> *)options {
    if (self = [super init]) {
        _image = CGImageRetain(cgImage);
        _dimensions = (MTITextureDimensions){CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 1};
        _options = [options copy];
    }
    return self;
}

- (void)dealloc {
    CGImageRelease(_image);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithCGImage:self.image options:self.options error:error];
    return [renderingContext.context newRenderTargetWithTexture:texture];
}

@end

@interface MTITexturePromise ()

@property (nonatomic,strong) id<MTLTexture> texture;

@end

@implementation MTITexturePromise

@synthesize dimensions = _dimensions;

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _dimensions = (MTITextureDimensions){texture.width, texture.height, texture.depth};
        _texture = texture;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    return [renderingContext.context newRenderTargetWithTexture:self.texture];
}

@end

@interface MTICIImagePromise ()

@property (nonatomic,strong) CIImage *image;

@property (nonatomic,copy) MTITextureDescriptor *textureDescriptor;

@end

@implementation MTICIImagePromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    if (self = [super init]) {
        _image = ciImage;
        _dimensions = (MTITextureDimensions){ciImage.extent.size.width, ciImage.extent.size.height, 1};
        _textureDescriptor = [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:ciImage.extent.size.width height:ciImage.extent.size.height mipmapped:NO] newMTITextureDescriptor];
    }
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        CIRenderDestination *renderDestination = [[CIRenderDestination alloc] initWithMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer];
        renderDestination.flipped = YES;
        renderDestination.colorSpace = (CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB());
        NSError *error;
        [renderingContext.context.coreImageContext startTaskToRender:self.image toDestination:renderDestination error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    } else {
        [renderingContext.context.coreImageContext render:[self.image imageByApplyingOrientation:4] toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:self.image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
    }
#else
    [renderingContext.context.coreImageContext render:self.image toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:self.image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
#endif
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface MTITextureDescriptorPromise ()

@property (nonatomic,copy) MTITextureDescriptor *textureDescriptor;

@end

@implementation MTITextureDescriptorPromise

@synthesize dimensions = _dimensions;

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor {
    if (self = [super init]) {
        _textureDescriptor = [[MTITextureDescriptor alloc] initWithMTLTextureDescriptor:textureDescriptor];
        _dimensions = (MTITextureDimensions){textureDescriptor.width, textureDescriptor.height, textureDescriptor.depth};
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    return [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
}

@end
