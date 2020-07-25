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
#import "MTIImageProperties.h"
#import "MTIDefer.h"
#import "MTIVertex.h"

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
        _dimensions = promise.dimensions;
        _samplerDescriptor = [samplerDescriptor copy];
        _cachePolicy = cachePolicy;
        _alphaType = promise.alphaType;
    }
    return self;
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise cachePolicy:(MTIImageCachePolicy)cachePolicy {
    return [self initWithPromise:promise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:cachePolicy];
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    return [self initWithPromise:promise samplerDescriptor:samplerDescriptor cachePolicy:MTIImageCachePolicyTransient];
}

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    if ([samplerDescriptor isEqual:_samplerDescriptor]) {
        return self;
    }
    return [[MTIImage alloc] initWithPromise:_promise samplerDescriptor:samplerDescriptor cachePolicy:_cachePolicy];
}

- (instancetype)imageWithCachePolicy:(MTIImageCachePolicy)cachePolicy {
    if (cachePolicy == _cachePolicy) {
        return self;
    }
    return [[MTIImage alloc] initWithPromise:_promise samplerDescriptor:_samplerDescriptor cachePolicy:cachePolicy];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)debugQuickLookObject {
    return [MTIImagePromiseDebugInfo layerRepresentationOfRenderGraphForPromise:self.promise];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; width = %@; height = %@; depth = %@; cachePolicy = %@; promise = %@>",self.class, self, @(self.dimensions.width), @(self.dimensions.height), @(self.dimensions.depth), @(self.cachePolicy), self.promise];
}

@end

@implementation MTIImage (Dimensions2D)

- (CGRect)extent {
    return CGRectMake(0, 0, _dimensions.width, _dimensions.height);
}

- (CGSize)size {
    return CGSizeMake(_dimensions.width, _dimensions.height);
}

@end

static MTIAlphaType MTIPreferredAlphaTypeForCVPixelBuffer(CVPixelBufferRef pixelBuffer) {
    MTIAlphaType alphaType = MTIAlphaTypeUnknown;
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        alphaType = MTIAlphaTypeAlphaIsOne;
    }
    NSCAssert(alphaType != MTIAlphaTypeUnknown, @"Cannot predicate alpha type. Please call the init method with the alphaType parameter.");
    if (alphaType == MTIAlphaTypeUnknown) {
        //We assume the alpha type to be non-premultiplied.
        alphaType = MTIAlphaTypeNonPremultiplied;
    }
    return alphaType;
}

static MTIAlphaType MTIPreferredAlphaTypeForImageWithProperties(MTIImageProperties *properties) {
    NSCParameterAssert(properties);
    CGImageAlphaInfo alphaInfo = properties.alphaInfo;
    MTIAlphaType alphaType = MTIAlphaTypeAlphaIsOne;
    switch (alphaInfo) {
        case kCGImageAlphaNone:
        case kCGImageAlphaNoneSkipLast:
        case kCGImageAlphaNoneSkipFirst:
            alphaType = MTIAlphaTypeAlphaIsOne;
            break;
        case kCGImageAlphaOnly:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
            alphaType = MTIAlphaTypeNonPremultiplied;
            break;
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaPremultipliedFirst:
            alphaType = MTIAlphaTypePremultiplied;
            break;
        default:
            NSCAssert(NO, @"Unknown alphaInfo.");
            break;
    }
    return alphaType;
}

static MTIAlphaType MTIPreferredAlphaTypeForCGImage(CGImageRef cgImage) {
    NSCParameterAssert(cgImage);
    return MTIPreferredAlphaTypeForImageWithProperties([[MTIImageProperties alloc] initWithCGImage:cgImage]);
}

#import "MTIImagePromise.h"

@implementation MTIImage (Creation)

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:MTICVPixelBufferRenderingOptions.defaultOptions alphaType:MTIPreferredAlphaTypeForCVPixelBuffer(pixelBuffer)]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer alphaType:(MTIAlphaType)alphaType {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:MTICVPixelBufferRenderingOptions.defaultOptions alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer renderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI alphaType:(MTIAlphaType)alphaType {
    MTICVPixelBufferRenderingOptions *options = [[MTICVPixelBufferRenderingOptions alloc] initWithRenderingAPI:renderingAPI sRGB:NO];
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:options alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer options:(MTICVPixelBufferRenderingOptions *)options alphaType:(MTIAlphaType)alphaType {
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
        pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
        pixelFormatType == kCVPixelFormatType_OneComponent8 ||
        pixelFormatType == kCVPixelFormatType_OneComponent16Half ||
        pixelFormatType == kCVPixelFormatType_OneComponent32Float
        ) {
        NSAssert(alphaType == MTIAlphaTypeAlphaIsOne, @"Alpha type should be `.alphaIsOne` for `CVPixelBuffer`s without a alpha channel.");
    }
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer options:options alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(NSUInteger)planeIndex textureDescriptor:(MTLTextureDescriptor *)textureDescriptor alphaType:(MTIAlphaType)alphaType {
    return [[[MTIImage alloc] initWithPromise:[[MTICVPixelBufferDirectBridgePromise alloc] initWithCVPixelBuffer:pixelBuffer planeIndex:planeIndex textureDescriptor:textureDescriptor alphaType:alphaType]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options {
    return [self initWithCGImage:cgImage options:options isOpaque:NO];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    return [self initWithCGImage:cgImage options:options isOpaque:alphaType == MTIAlphaTypeAlphaIsOne];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options isOpaque:(BOOL)isOpaque {
    NSParameterAssert(cgImage);
    MTIAlphaType preferredAlphaType = isOpaque ? MTIAlphaTypeAlphaIsOne : MTIPreferredAlphaTypeForCGImage(cgImage);
    return [self initWithPromise:[[MTILegacyCGImagePromise alloc] initWithCGImage:cgImage options:options alphaType:preferredAlphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage loadingOptions:(MTICGImageLoadingOptions *)options {
    return [self initWithCGImage:cgImage orientation:kCGImagePropertyOrientationUp loadingOptions:options isOpaque:NO];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage loadingOptions:(MTICGImageLoadingOptions *)options isOpaque:(BOOL)isOpaque {
    MTIAlphaType preferredAlphaType = isOpaque ? MTIAlphaTypeAlphaIsOne : MTIPreferredAlphaTypeForCGImage(cgImage);
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage orientation:kCGImagePropertyOrientationUp options:options alphaType:preferredAlphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation loadingOptions:(MTICGImageLoadingOptions *)options isOpaque:(BOOL)isOpaque {
    MTIAlphaType preferredAlphaType = isOpaque ? MTIAlphaTypeAlphaIsOne : MTIPreferredAlphaTypeForCGImage(cgImage);
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage orientation:orientation options:options alphaType:preferredAlphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    return [self initWithCIImage:ciImage isOpaque:NO];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage bounds:ciImage.extent isOpaque:isOpaque options:MTICIImageRenderingOptions.defaultOptions] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage bounds:ciImage.extent isOpaque:isOpaque options:options] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage bounds:(CGRect)bounds isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage bounds:bounds isOpaque:isOpaque options:options] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}


- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption, id> *)options {
    MTIImageProperties *properties = [[MTIImageProperties alloc] initWithImageAtURL:URL];
    if (!properties) {
        return nil;
    }
    MTITextureDimensions dimensions = (MTITextureDimensions){.width = properties.displayWidth, .height = properties.displayHeight, .depth = 1};
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL dimensions:dimensions options:options alphaType:MTIPreferredAlphaTypeForImageWithProperties(properties)];
    if (!urlPromise) {
        return nil;
    }
    return [self initWithPromise:urlPromise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption, id> *)options alphaType:(MTIAlphaType)alphaType {
    MTIImageProperties *properties = [[MTIImageProperties alloc] initWithImageAtURL:URL];
    if (!properties) {
        return nil;
    }
    MTIAlphaType preferredAlphaType = MTIPreferredAlphaTypeForImageWithProperties(properties);
    if (preferredAlphaType == MTIAlphaTypePremultiplied) {
        NSAssert(alphaType != MTIAlphaTypeNonPremultiplied, @"The bitmap info indicates the alpha type is `.premultiplied`.");
    }
    MTITextureDimensions dimensions = (MTITextureDimensions){.width = properties.displayWidth, .height = properties.displayHeight, .depth = 1};
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL dimensions:dimensions options:options alphaType:alphaType];
    if (!urlPromise) {
        return nil;
    }
    return [self initWithPromise:urlPromise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL size:(CGSize)size options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL dimensions:(MTITextureDimensions){.width = size.width, .height = size.height, .depth = 1} options:options alphaType:alphaType];
    if (!urlPromise) {
        return nil;
    }
    return [self initWithPromise:urlPromise samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL loadingOptions:(MTICGImageLoadingOptions *)options {
    MTIImageProperties *properties = [[MTIImageProperties alloc] initWithImageAtURL:URL];
    if (!properties) {
        return nil;
    }
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)URL, nil);
    if (!imageSource || CGImageSourceGetCount(imageSource) == 0) {
        return nil;
    }
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
    CFRelease(imageSource);
    if (!cgImage) {
        return nil;
    }
    @MTI_DEFER {
        CGImageRelease(cgImage);
    };
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage orientation:properties.orientation options:options alphaType:MTIPreferredAlphaTypeForImageWithProperties(properties)] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL loadingOptions:(MTICGImageLoadingOptions *)options alphaType:(MTIAlphaType)alphaType {
    MTIImageProperties *properties = [[MTIImageProperties alloc] initWithImageAtURL:URL];
    if (!properties) {
        return nil;
    }
    MTIAlphaType preferredAlphaType = MTIPreferredAlphaTypeForImageWithProperties(properties);
    if (preferredAlphaType == MTIAlphaTypePremultiplied) {
        NSAssert(alphaType != MTIAlphaTypeNonPremultiplied, @"The bitmap info indicates the alpha type is `.premultiplied`.");
    }
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)URL, nil);
    if (!imageSource || CGImageSourceGetCount(imageSource) == 0) {
        return nil;
    }
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
    CFRelease(imageSource);
    if (!cgImage) {
        return nil;
    }
    @MTI_DEFER {
        CGImageRelease(cgImage);
    };
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage orientation:properties.orientation options:options alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
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

- (instancetype)initWithMDLTexture:(MDLTexture *)texture options:(NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType {
    return [self initWithPromise:[[MTIMDLTexturePromise alloc] initWithMDLTexture:texture options:options alphaType:alphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
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
