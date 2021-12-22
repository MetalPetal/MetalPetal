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
#import "MTITextureLoader.h"
#import "MTIDefer.h"

@interface MTIImageURLPromise ()

@property (nonatomic, copy, readonly) NSURL *URL;

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption, id> *options;

@end

@implementation MTIImageURLPromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithContentsOfURL:(NSURL *)URL
                           dimensions:(MTITextureDimensions)dimensions
                              options:(NSDictionary<MTKTextureLoaderOption, id> *)options
                            alphaType:(MTIAlphaType)alphaType {
    if (self = [super init]) {
        _URL = [URL copy];
        _options = [options copy];
        _alphaType = alphaType;
        _dimensions = dimensions;
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
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:self.URL];
}

@end

@interface MTILegacyCGImagePromise ()

@property (nonatomic, readonly) CGImageRef image;

@property (nonatomic, copy, readonly) NSDictionary<MTKTextureLoaderOption, id> *options;

@end

@implementation MTILegacyCGImagePromise
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

@implementation MTICGImageLoadingOptions

+ (MTICGImageLoadingOptions *)defaultOptions {
    static MTICGImageLoadingOptions *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        options = [[MTICGImageLoadingOptions alloc] initWithColorSpace:colorSpace];
        CGColorSpaceRelease(colorSpace);
    });
    return options;
}

+ (MTLTextureDescriptor *)defaultTextureDescriptor {
    static MTLTextureDescriptor *textureDescriptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        textureDescriptor = [[MTLTextureDescriptor alloc] init];
    });
    return textureDescriptor;
}

- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace {
    return [self initWithColorSpace:colorSpace flipsVertically:NO storageMode:MTICGImageLoadingOptions.defaultTextureDescriptor.storageMode cpuCacheMode:MTICGImageLoadingOptions.defaultTextureDescriptor.cpuCacheMode];
}

- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace flipsVertically:(BOOL)flipsVertically {
    return [self initWithColorSpace:colorSpace flipsVertically:flipsVertically storageMode:MTICGImageLoadingOptions.defaultTextureDescriptor.storageMode cpuCacheMode:MTICGImageLoadingOptions.defaultTextureDescriptor.cpuCacheMode];
}

- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace flipsVertically:(BOOL)flipsVertically storageMode:(MTLStorageMode)storageMode cpuCacheMode:(MTLCPUCacheMode)cpuCacheMode {
    if (self = [super init]) {
        _colorSpace = CGColorSpaceRetain(colorSpace);
        _flipsVertically = flipsVertically;
        _storageMode = storageMode;
        _cpuCacheMode = cpuCacheMode;
    }
    return self;
}

- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface MTICGImagePromise ()

@property (nonatomic, readonly) CGImageRef image;

@property (nonatomic, copy, readonly) MTICGImageLoadingOptions *options;

@property (nonatomic, copy, readonly) MTIImageProperties *properties;

@end

@implementation MTICGImagePromise
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (instancetype)initWithCGImage:(CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation options:(MTICGImageLoadingOptions *)options isOpaque:(BOOL)isOpaque {
    if (self = [super init]) {
        _properties = [[MTIImageProperties alloc] initWithCGImage:cgImage orientation:orientation];
        _image = CGImageRetain(cgImage);
        _dimensions = (MTITextureDimensions){_properties.displayWidth, _properties.displayHeight, 1};
        _options = [options copy] ?: MTICGImageLoadingOptions.defaultOptions;
        _alphaType = isOpaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied; // kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    size_t pixelWidth = _properties.pixelWidth;
    size_t pixelHeight = _properties.pixelHeight;
    size_t displayWidth = _properties.displayWidth;
    size_t displayHeight = _properties.displayHeight;
    CVPixelBufferRef pixelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault,
                        displayWidth,
                        displayHeight,
                        kCVPixelFormatType_32BGRA,
                        (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                        &pixelBuffer);
    if (!pixelBuffer) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCVPixelBuffer, nil);
        }
        return nil;
    }
    
    @MTI_DEFER {
        CVPixelBufferRelease(pixelBuffer);
    };
    
    CGColorSpaceRef colorSpace = nil;
    CGColorSpaceRef specifiedColorSpace = _options.colorSpace ?: CGImageGetColorSpace(_image);
    if (CGColorSpaceGetModel(specifiedColorSpace) == kCGColorSpaceModelRGB) {
        colorSpace = CGColorSpaceRetain(specifiedColorSpace);
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer),
                                                   displayWidth,
                                                   displayHeight,
                                                   8,
                                                   CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                   colorSpace,
                                                   kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!cgContext) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorTextureLoaderFailedToCreateCGContext, nil);
        }
        return nil;
    }
    
    CIImage *placeholder = [[CIImage imageWithColor:CIColor.blackColor] imageByCroppingToRect:CGRectMake(0, 0, pixelWidth, pixelHeight)];
    if (_options.flipsVertically) {
        CGContextConcatCTM(cgContext, CGAffineTransformMake(1, 0, 0, -1, 0, displayHeight));
    }
    CGContextConcatCTM(cgContext, [placeholder imageTransformForOrientation:_properties.orientation]);
    CGContextDrawImage(cgContext, CGRectMake(0, 0, pixelWidth, pixelHeight), _image);
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    IOSurfaceRef iosurface = CVPixelBufferGetIOSurface(pixelBuffer);
    if (!iosurface) {
        NSAssert(NO, @"CVPixelBuffer is not backed by an IOSurface, please file a bug report.");
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = _options.storageMode;
    textureDescriptor.cpuCacheMode = _options.cpuCacheMode;
    
    id<MTLTexture> texture = [renderingContext.context.device newTextureWithDescriptor:textureDescriptor iosurface:CVPixelBufferGetIOSurface(pixelBuffer) plane:0];
    if (!texture) {
        if (inOutError) {
            *inOutError = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    
    #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
    //Workaround for #64. See https://github.com/MetalPetal/MetalPetal/issues/64
    if (![renderingContext.context.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1]) {
        NSError *error;
        MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:textureDescriptor.newMTITextureDescriptor error:&error];
        if (error) {
            if (inOutError) {
                *inOutError = error;
            }
            return nil;
        }
        id<MTLBlitCommandEncoder> commandEncoder = [renderingContext.commandBuffer blitCommandEncoder];
        if (!commandEncoder) {
            if (inOutError) {
                *inOutError = MTIErrorCreate(MTIErrorFailedToCreateCommandEncoder, nil);
            }
            return nil;
        }
        [commandEncoder copyFromTexture:texture sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(texture.width, texture.height, texture.depth) toTexture:renderTarget.texture destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)];
        [commandEncoder endEncoding];
        return renderTarget;
    }
    #endif
    
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
    NSParameterAssert(renderingContext.context.device == _texture.device);
    if (renderingContext.context.device != _texture.device) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorCrossDeviceRendering, nil);
        }
        return nil;
    }
    return [renderingContext.context newRenderTargetWithTexture:_texture];
}

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:_texture];
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
        switch (self.options.alphaMode) {
            case CIRenderDestinationAlphaNone:
                return MTIAlphaTypeAlphaIsOne;
            case CIRenderDestinationAlphaPremultiplied:
                return MTIAlphaTypePremultiplied;
            case CIRenderDestinationAlphaUnpremultiplied:
                return MTIAlphaTypeNonPremultiplied;
            default:
                NSAssert(NO, @"Unknown CIRenderDestinationAlphaMode");
                return MTIAlphaTypePremultiplied;
        }
    }
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)inOutError {
    NSError *error;
    MTIImagePromiseRenderTarget *renderTarget = [renderingContext.context newRenderTargetWithReusableTextureDescriptor:self.textureDescriptor error:&error];
    if (error) {
        if (inOutError) {
            *inOutError = error;
        }
        return nil;
    }
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
