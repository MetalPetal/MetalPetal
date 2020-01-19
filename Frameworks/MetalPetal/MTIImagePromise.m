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
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"
#import "MTICoreImageRendering.h"
#import "MTIImageProperties.h"

static NSString * const MTIMTKTextureLoaderCannotDecodeImageMessage = @"MetalPetal uses `MTKTextureLoader` to load `CGImage`s. However this image may not be able to load using MTKTextureLoader, see http://www.openradar.me/31722523. You can use `MTIImage(ciImage:isOpaque:)` to load the image using CoreImage. Or use a texture asset with `MTIImage(named:in:...)`";

BOOL MTIMTKTextureLoaderCanDecodeImage(CGImageRef image) {
    NSCParameterAssert(image);
    CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorspace);
    if (model == kCGColorSpaceModelRGB) {
        return YES;
    }
    return NO;
}

@interface MTIImageURLPromise ()

@property (nonatomic, copy, readonly) NSURL *URL;

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption, id> *options;

@property (nonatomic, copy, readonly) MTIImageProperties *properties;

@end

@implementation MTIImageURLPromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithContentsOfURL:(NSURL *)URL
                           properties:(MTIImageProperties *)properties
                              options:(NSDictionary<MTKTextureLoaderOption, id> *)options
                            alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _URL = [URL copy];
        _options = [options copy];
        _alphaType = alphaType;
        _properties = properties;
        _dimensions = (MTITextureDimensions){.width = properties.displayWidth, .height = properties.displayHeight, .depth = 1};
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithContentsOfURL:self.URL options:self.options error:error];
    if (!texture) {
        return nil;
    }
    return [renderingContext.context newRenderTargetWithTexture:texture];
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:self.URL];
}

@end

@interface MTICGImagePromise ()

@property (nonatomic, readonly) CGImageRef image;

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption, id> *options;

@end

@implementation MTICGImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        NSAssert(MTIMTKTextureLoaderCanDecodeImage(cgImage), MTIMTKTextureLoaderCannotDecodeImageMessage);
        _image = CGImageRetain(cgImage);
        _dimensions = (MTITextureDimensions){CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 1};
        _options = [options copy];
        _alphaType = alphaType;
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithCGImage:self.image options:self.options error:error];
    if (!texture) {
        return nil;
    }
    if (@available(iOS 12.0, macOS 10.14, *)) {
        id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
        [blitCommandEncoder optimizeContentsForGPUAccess:texture];
        [blitCommandEncoder endEncoding];
    }
    return [renderingContext.context newRenderTargetWithTexture:texture];
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:(id)self.image];
}

@end

@interface MTITexturePromise ()

@property (nonatomic, strong, readonly) id<MTLTexture> texture;

@end

@implementation MTITexturePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _dimensions = (MTITextureDimensions){texture.width, texture.height, texture.depth};
        _texture = texture;
        _alphaType = alphaType;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    NSParameterAssert(renderingContext.context.device == self.texture.device);
    if (renderingContext.context.device != self.texture.device) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorCrossDeviceRendering, nil);
        }
        return nil;
    }
    return [renderingContext.context newRenderTargetWithTexture:self.texture];
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:self.texture];
}

@end

@interface MTICIImagePromise ()

@property (nonatomic, copy, readonly) CIImage *image;

@property (nonatomic, readonly) CGRect bounds;

@property (nonatomic, copy, readonly) MTITextureDescriptor *textureDescriptor;

@property (nonatomic, readonly) BOOL isOpaque;

@property (nonatomic, copy, readonly) MTICIImageRenderingOptions *options;

@end

@implementation MTICIImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCIImage:(CIImage *)ciImage bounds:(CGRect)bounds isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options {
    if (self = [super init]) {
        _image = ciImage;
        _bounds = bounds;
        _isOpaque = isOpaque;
        _dimensions = (MTITextureDimensions){ciImage.extent.size.width, ciImage.extent.size.height, 1};
        _textureDescriptor = [MTITextureDescriptor texture2DDescriptorWithPixelFormat:options.destinationPixelFormat width:ciImage.extent.size.width height:ciImage.extent.size.height mipmapped:NO usage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead resourceOptions:MTLResourceStorageModePrivate];
        _options = [options copy];
    }
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIAlphaType)alphaType {
    if (_isOpaque) {
        return MTIAlphaTypeAlphaIsOne;
    } else {
        if (@available(iOS 11.0, *)) {
            switch (self.options.alphaMode) {
                case CIRenderDestinationAlphaNone:
                    return MTIAlphaTypeAlphaIsOne;
                case CIRenderDestinationAlphaPremultiplied:
                    return MTIAlphaTypePremultiplied;
                case CIRenderDestinationAlphaUnpremultiplied:
                    return MTIAlphaTypeNonPremultiplied;
                default:
                    NSAssert(NO, @"Unknown CIRenderDestinationAlphaMode");
                    break;
            }
        }
        return MTIAlphaTypePremultiplied;
    }
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSError *error;
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithResuableTextureDescriptor:self.textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
    if (@available(iOS 11.0, *)) {
        CIRenderDestination *renderDestination = [[CIRenderDestination alloc] initWithMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer];
        renderDestination.flipped = self.options.isFlipped;
        renderDestination.colorSpace = self.options.colorSpace;
        renderDestination.alphaMode = self.options.alphaMode;
        [renderingContext.context.coreImageContext startTaskToRender:self.image fromRect:self.bounds toDestination:renderDestination atPoint:CGPointZero error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    } else {
        [renderingContext.context.coreImageContext render:(self.options.isFlipped ? [self.image imageByApplyingOrientation:4] : self.image) toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:self.bounds colorSpace:self.options.colorSpace];
    }
    return renderTarget;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:self.image];
}

@end

@interface MTIColorImagePromise ()

@property (nonatomic, readonly) BOOL sRGB;

@end

@implementation MTIColorImagePromise
@synthesize dimensions = _dimensions;

- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size {
    if (self = [super init]) {
        _dimensions = (MTITextureDimensions){size.width,size.height,1};
        _color = color;
        _sRGB = sRGB;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.width = 1;
    textureDescriptor.height = 1;
    textureDescriptor.depth = 1;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    if (_sRGB) {
        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    } else {
        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    //It's not safe to reuse a GPU texture here, 'cause we're going to fill its content using CPU.
    id<MTLTexture> texture = [renderingContext.context.device newTextureWithDescriptor:textureDescriptor];
    if (!texture) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    simd_float4 floatColor = simd_clamp(MTIColorToFloat4(_color), simd_make_float4(0,0,0,0), simd_make_float4(1,1,1,1)) * 255.0;
    uint8_t colors[4] = {round(floatColor.b), round(floatColor.g), round(floatColor.r), round(floatColor.a)};
    [texture replaceRegion:MTLRegionMake2D(0, 0, textureDescriptor.width, textureDescriptor.height) mipmapLevel:0 slice:0 withBytes:colors bytesPerRow:4 * textureDescriptor.width bytesPerImage:4 * textureDescriptor.width * textureDescriptor.height];
    
    if (@available(iOS 12.0, macOS 10.14, *)) {
        id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
        [blitCommandEncoder optimizeContentsForGPUAccess:texture];
        [blitCommandEncoder endEncoding];
    }
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithTexture:texture];
    return renderTarget;
}

- (MTIAlphaType)alphaType {
    if (_color.alpha == 1) {
        return MTIAlphaTypeAlphaIsOne;
    }
    return MTIAlphaTypeNonPremultiplied;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:@[@(self.color.red), @(self.color.green), @(self.color.blue), @(self.color.alpha)]];
}

@end

@interface MTIBitmapDataImagePromise ()

@property (nonatomic, copy, readonly) NSData *data;

@property (nonatomic, readonly) MTLPixelFormat pixelFormat;

@property (nonatomic, readonly) NSUInteger bytesPerRow;

@end

@implementation MTIBitmapDataImagePromise
@synthesize alphaType = _alphaType;
@synthesize dimensions = _dimensions;

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        NSParameterAssert(width > 0);
        NSParameterAssert(height > 0);
        NSParameterAssert(data.length == height * bytesPerRow);
        _data = [data copy];
        _dimensions = (MTITextureDimensions){.width = width, .height = height, .depth = 1};
        _pixelFormat = pixelFormat;
        _alphaType = alphaType;
        _bytesPerRow = bytesPerRow;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.width = _dimensions.width;
    textureDescriptor.height = _dimensions.height;
    textureDescriptor.depth = _dimensions.depth;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = _pixelFormat;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    //It's not safe to reuse a GPU texture here, 'cause we're going to fill its content using CPU.
    id<MTLTexture> texture = [renderingContext.context.device newTextureWithDescriptor:textureDescriptor];
    if (!texture) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    
    [texture replaceRegion:MTLRegionMake2D(0, 0, textureDescriptor.width, textureDescriptor.height) mipmapLevel:0 slice:0 withBytes:_data.bytes bytesPerRow:_bytesPerRow bytesPerImage:_bytesPerRow * textureDescriptor.height];
    
    if (@available(iOS 12.0, macOS 10.14, *)) {
        id<MTLBlitCommandEncoder> blitCommandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
        [blitCommandEncoder optimizeContentsForGPUAccess:texture];
        [blitCommandEncoder endEncoding];
    }
    
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithTexture:texture];
    return renderTarget;
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:@"BitmapData"];
}

@end

@interface MTINamedImagePromise ()

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption,id> *options;

@end

@implementation MTINamedImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle size:(CGSize)size scaleFactor:(CGFloat)scaleFactor options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _name = [name copy];
        _bundle = bundle;
        _dimensions = MTITextureDimensionsMake2DFromCGSize(size);
        _scaleFactor = scaleFactor;
        _options = [options copy];
        _alphaType = alphaType;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithName:self.name scaleFactor:self.scaleFactor bundle:self.bundle options:self.options error:error];
    if (!texture) {
        return nil;
    }
    if (texture.width == self.dimensions.width && texture.height == self.dimensions.height && texture.depth == self.dimensions.depth) {
        return [renderingContext.context newRenderTargetWithTexture:texture];
    } else {
        if (error) {
            *error = MTIErrorCreate(MTIErrorTextureDimensionsMismatch, nil);
        }
        return nil;
    }
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
#if TARGET_OS_IPHONE
    #define MTIStringFromSize NSStringFromCGSize
#else
    #define MTIStringFromSize NSStringFromSize
#endif
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:[NSString stringWithFormat:@"Name: %@\nBundle: %@\nScale:%@\nSize:%@",self.name,self.bundle,@(self.scaleFactor),MTIStringFromSize(CGSizeMake(self.dimensions.width, self.dimensions.height))]];
}

@end

@interface MTIMDLTexturePromise ()

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption,id> *options;

@property (nonatomic, strong, readonly) MDLTexture *texture;

@end

@implementation MTIMDLTexturePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithMDLTexture:(MDLTexture *)texture
                           options:(NSDictionary<MTKTextureLoaderOption,id> *)options
                         alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _texture = texture;
        _options = [options copy];
        _dimensions = (MTITextureDimensions){
            .width = texture.dimensions.x,
            .height = texture.isCube ? texture.dimensions.y / 6 : texture.dimensions.y,
            .depth = 1
        };
        _alphaType = alphaType;
    }
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)promiseByUpdatingDependencies:(nonnull NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(nonnull MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithMDLTexture:_texture
                                                             options:_options
                                                               error:error];
    if (!texture) {
        return nil;
    }
    if (texture.width == self.dimensions.width && texture.height == self.dimensions.height && texture.depth == self.dimensions.depth) {
        return [renderingContext.context newRenderTargetWithTexture:texture];
    } else {
        if (error) {
            *error = MTIErrorCreate(MTIErrorTextureDimensionsMismatch, nil);
        }
        return nil;
    }
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self
                                                        type:MTIImagePromiseTypeSource
                                                     content:[NSString stringWithFormat:@"Name: %@\nTexture:%@",self.texture.name,self.texture]];
}

@end
