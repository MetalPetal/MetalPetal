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
#import "MTKTextureLoaderExtensions.h"
#import "MTIContext+Internal.h"
#import "MTICoreImageRendering.h"

static NSDictionary<MTKTextureLoaderOption, id> * MTIProcessMTKTextureLoaderOptions(NSDictionary<MTKTextureLoaderOption, id> *options) {
    if (MTIMTKTextureLoaderExtensions.automaticallyFlipsTextureOniOS9) {
        NSMutableDictionary *opt = [NSMutableDictionary dictionaryWithDictionary:options];
        if (opt[MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9] == nil) {
            opt[MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9] = @(4);
        }
        return opt;
    }
    return options;
}

@interface MTIImageURLPromise ()

@property (nonatomic,copy) NSURL *URL;

@property (nonatomic,copy) NSDictionary<MTKTextureLoaderOption, id> *options;

@property (nonatomic,strong) MDLURLTexture *texture;

@end

@implementation MTIImageURLPromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption, id> *)options alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _URL = [URL copy];
        _options = [options copy];
        _texture = [[MDLURLTexture alloc] initWithURL:URL name:URL.lastPathComponent];
        _dimensions = (MTITextureDimensions){_texture.dimensions.x, _texture.dimensions.y, 1};
        _alphaType = alphaType;
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
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithContentsOfURL:self.URL options:MTIProcessMTKTextureLoaderOptions(self.options) error:error];
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

@property (nonatomic) CGImageRef image;

@property (nonatomic,copy) NSDictionary<MTKTextureLoaderOption, id> *options;

@end

@implementation MTICGImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithCGImage:self.image options:MTIProcessMTKTextureLoaderOptions(self.options) error:error];
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
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:(id)self.image];
}

@end

@interface MTITexturePromise ()

@property (nonatomic,strong) id<MTLTexture> texture;

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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
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

@property (nonatomic,strong) CIImage *image;

@property (nonatomic,copy) MTITextureDescriptor *textureDescriptor;

@property (nonatomic,readonly) BOOL isOpaque;

@property (nonatomic,copy) MTICIImageRenderingOptions *options;

@end

@implementation MTICIImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options {
    if (self = [super init]) {
        _image = ciImage;
        _isOpaque = isOpaque;
        _dimensions = (MTITextureDimensions){ciImage.extent.size.width, ciImage.extent.size.height, 1};
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:options.destinationPixelFormat width:ciImage.extent.size.width height:ciImage.extent.size.height mipmapped:NO];
        textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
        _textureDescriptor = [textureDescriptor newMTITextureDescriptor];
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
        return MTIAlphaTypePremultiplied;
    }
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)inOutError {
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
        renderDestination.alphaMode = CIRenderDestinationAlphaPremultiplied;
        [renderingContext.context.coreImageContext startTaskToRender:self.image toDestination:renderDestination error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
    } else {
        [renderingContext.context.coreImageContext render:self.options.isFlipped ? [self.image imageByApplyingOrientation:4] : self.image toMTLTexture:renderTarget.texture commandBuffer:renderingContext.commandBuffer bounds:self.image.extent colorSpace:self.options.colorSpace];
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

@property (nonatomic,readonly) BOOL sRGB;

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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.width = 1;
    textureDescriptor.height = 1;
    textureDescriptor.depth = 1;
    textureDescriptor.textureType = MTLTextureType2D;
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
    uint8_t colors[4] = {round(_color.blue * 255), round(_color.green * 255), round(_color.red * 255), round(_color.alpha * 255)};
    [texture replaceRegion:MTLRegionMake2D(0, 0, textureDescriptor.width, textureDescriptor.height) mipmapLevel:0 slice:0 withBytes:colors bytesPerRow:4 * textureDescriptor.width bytesPerImage:4 * textureDescriptor.width * textureDescriptor.height];
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

@property (nonatomic,copy,readonly) NSData *data;

@property (nonatomic,readonly) MTLPixelFormat pixelFormat;

@property (nonatomic,readonly) NSUInteger bytesPerRow;

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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.width = _dimensions.width;
    textureDescriptor.height = _dimensions.height;
    textureDescriptor.depth = _dimensions.depth;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = _pixelFormat;
    //It's not safe to reuse a GPU texture here, 'cause we're going to fill its content using CPU.
    id<MTLTexture> texture = [renderingContext.context.device newTextureWithDescriptor:textureDescriptor];
    if (!texture) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    [texture replaceRegion:MTLRegionMake2D(0, 0, textureDescriptor.width, textureDescriptor.height) mipmapLevel:0 slice:0 withBytes:_data.bytes bytesPerRow:_bytesPerRow bytesPerImage:_bytesPerRow * textureDescriptor.height];
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

@property (nonatomic, copy) NSDictionary<MTKTextureLoaderOption,id> *options;

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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithName:self.name scaleFactor:self.scaleFactor bundle:self.bundle options:MTIProcessMTKTextureLoaderOptions(self.options) error:error];
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
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:[NSString stringWithFormat:@"Name: %@\nBundle: %@\nScale:%@\nSize:%@",self.name,self.bundle,@(self.scaleFactor),NSStringFromCGSize(CGSizeMake(self.dimensions.width, self.dimensions.height))]];
}

@end
