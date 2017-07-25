//
//  MTIImagePromise.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIImagePromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIContext.h"
#import "MTITextureDescriptor.h"

@interface MTIImageURLPromise ()

@property (nonatomic,copy) NSURL *URL;

@property (nonatomic,copy) NSDictionary *options;

@property (nonatomic,strong) MDLURLTexture *texture;

@end

@implementation MTIImageURLPromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary *)options {
    if (self = [super init]) {
        _URL = [URL copy];
        _options = [options copy];
        _texture = [[MDLURLTexture alloc] initWithURL:URL name:URL.lastPathComponent];
        _dimensions = (MTITextureDimensions){_texture.dimensions.x, _texture.dimensions.y, 1};
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
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithMDLTexture:self.texture options:self.options error:error];
    return [renderingContext.context newRenderTargetWithTexture:texture];
}

@end

@interface MTICGImagePromise ()

@property (nonatomic) CGImageRef image;

@end

@implementation MTICGImagePromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithCGImage:(CGImageRef)cgImage {
    if (self = [super init]) {
        _image = CGImageRetain(cgImage);
        _dimensions = (MTITextureDimensions){CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 1};
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
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithCGImage:self.image options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:error];
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor];
    [renderingContext.context.coreImageContext render:self.image toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:self.image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
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
