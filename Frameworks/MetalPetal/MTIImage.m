//
//  MTIImage.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImage.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIImage+Promise.h"
#import "MTICVPixelBufferPromise.h"
#import "MTICoreImageRendering.h"
#import "MTIImagePromiseDebug.h"

@interface MTIImage ()

@property (nonatomic,copy,readonly) id<MTIImagePromise> promise;

@end

@implementation MTIImage

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise {
    return [self initWithPromise:promise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor];
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor cachePolicy:(MTIImageCachePolicy)cachePolicy {
    if (self = [super init]) {
        _promise = [promise copyWithZone:nil];
        _extent = CGRectMake(0, 0, _promise.dimensions.width, _promise.dimensions.height);
        _samplerDescriptor = [samplerDescriptor copy];
        _cachePolicy = cachePolicy;
    }
    return self;
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    return [self initWithPromise:promise samplerDescriptor:samplerDescriptor cachePolicy:MTIImageCachePolicyTransient];
}

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    return [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:samplerDescriptor cachePolicy:self.cachePolicy];
}

- (instancetype)imageWithCachePolicy:(MTIImageCachePolicy)cachePolicy {
    return [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:self.samplerDescriptor cachePolicy:cachePolicy];
}

- (CGSize)size {
    return _extent.size;
}

- (MTIAlphaType)alphaType {
    return _promise.alphaType;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)debugQuickLookObject {
    return [MTIImagePromiseDebugInfo layerRepresentationOfRenderGraphForPromise:self.promise];
}

@end

#import "MTIImagePromise.h"

@implementation MTIImage (Creation)

+ (MTIAlphaType)alphaTypeGuessForCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    MTIAlphaType alphaType = MTIAlphaTypeUnknown;
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        alphaType = MTIAlphaTypeAlphaIsOne;
    }
    NSAssert(alphaType != MTIAlphaTypeUnknown, @"Cannot predicate alpha type. Please call the init method with the alphaType parameter.");
    if (alphaType == MTIAlphaTypeUnknown) {
        //We assume the alpha type to be non-premultiplied.
        alphaType = MTIAlphaTypeNonPremultiplied;
    }
    return alphaType;
}

+ (MTIAlphaType)alphaTypeGuessForURL:(NSURL *)url {
    static NSSet *opaqueImagePathExtensions;
    static NSSet *premultipliedAlphaImagePathExtensions;
    static NSSet *nonPremultipliedAlphaImagePathExtensions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        opaqueImagePathExtensions = [NSSet setWithObjects:@"jpg", @"jpeg", nil];
        nonPremultipliedAlphaImagePathExtensions = [NSSet set];
        premultipliedAlphaImagePathExtensions = [NSSet setWithObjects:@"png", @"tiff", nil];
    });
    MTIAlphaType alphaType = MTIAlphaTypeUnknown;
    if ([opaqueImagePathExtensions containsObject:url.pathExtension.lowercaseString]) {
        alphaType = MTIAlphaTypeAlphaIsOne;
    } else if ([nonPremultipliedAlphaImagePathExtensions containsObject:url.pathExtension.lowercaseString]) {
        alphaType = MTIAlphaTypeNonPremultiplied;
    } else if ([premultipliedAlphaImagePathExtensions containsObject:url.pathExtension.lowercaseString]) {
        alphaType = MTIAlphaTypePremultiplied;
    }
    NSAssert(alphaType != MTIAlphaTypeUnknown, @"Cannot predicate alpha type. Please call the init method with the alphaType parameter.");
    if (alphaType == MTIAlphaTypeUnknown) {
        //We assume the alpha type to be non-premultiplied.
        alphaType = MTIAlphaTypeNonPremultiplied;
    }
    return alphaType;
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:MTICVPixelBufferRenderingOptions.defaultOptions alphaType:[MTIImage alphaTypeGuessForCVPixelBuffer:pixelBuffer]]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer alphaType:(MTIAlphaType)alphaType {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:MTICVPixelBufferRenderingOptions.defaultOptions alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer renderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI alphaType:(MTIAlphaType)alphaType {
    MTICVPixelBufferRenderingOptions *options = [[MTICVPixelBufferRenderingOptions alloc] initWithRenderingAPI:renderingAPI sRGB:NO];
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:options alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer options:(MTICVPixelBufferRenderingOptions *)options alphaType:(MTIAlphaType)alphaType {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:options alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options {
    return [self initWithCGImage:cgImage options:options alphaType:MTIAlphaTypePremultiplied];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage options:options alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    return [self initWithCIImage:ciImage isOpaque:NO];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage isOpaque:isOpaque options:MTICIImageRenderingOptions.defaultOptions] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage isOpaque:isOpaque options:options] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption, id> *)options {
    return [self initWithContentsOfURL:URL options:options alphaType:[MTIImage alphaTypeGuessForURL:URL]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption, id> *)options alphaType:(MTIAlphaType)alphaType {
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL options:options alphaType:alphaType];
    if (!urlPromise) {
        return nil;
    }
    return [self initWithPromise:urlPromise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size {
    MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    return [self initWithPromise:[[MTIColorImagePromise alloc] initWithColor:color sRGB:sRGB size:size] samplerDescriptor:[samplerDescriptor newMTISamplerDescriptor] cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTIBitmapDataImagePromise alloc] initWithBitmapData:data width:width height:height bytesPerRow:bytesPerRow pixelFormat:pixelFormat alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle size:(CGSize)size scaleFactor:(CGFloat)scaleFactor options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTINamedImagePromise alloc] initWithName:name bundle:bundle size:size scaleFactor:scaleFactor options:options alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

+ (instancetype)whiteImage {
    static MTIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[MTIImage alloc] initWithColor:MTIColorMake(1, 1, 1, 1) sRGB:NO size:CGSizeMake(1, 1)];
    });
    return image;
}

+ (instancetype)blackImage {
    static MTIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[MTIImage alloc] initWithColor:MTIColorMake(0, 0, 0, 1) sRGB:NO size:CGSizeMake(1, 1)];
    });
    return image;
}

+ (instancetype)transparentImage {
    static MTIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[MTIImage alloc] initWithColor:MTIColorMake(0, 0, 0, 0) sRGB:NO size:CGSizeMake(1, 1)];
    });
    return image;
}

@end
