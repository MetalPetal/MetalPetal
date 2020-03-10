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

#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIFilter.h"
#import "MTIRenderPassOutputDescriptor.h"

@implementation MTIImage (Convert)

+ (MTIImage *)imageFromRGChannelMonochromeImage:(MTIImage *)image alphaInfo:(CGImageAlphaInfo)alphaInfo byteOrderInfo:(CGImageByteOrderInfo)byteOrderInfo sRGBToLinear:(BOOL)sRGBToLinear flip:(BOOL)flip {
    BOOL byteOrderLittle = NO;
    switch (byteOrderInfo) {
        case kCGImageByteOrder16Little:
            byteOrderLittle = YES;
            break;
        case kCGImageByteOrder16Big:
            byteOrderLittle = NO;
            break;
        case kCGImageByteOrderDefault:
            byteOrderLittle = NO;
            break;
        default:
            NSAssert(NO, @"");
            break;
    }
    BOOL alphaPremultiplied = YES;
    BOOL alphaFirst = NO;
    switch (alphaInfo) {
        case kCGImageAlphaLast:
            alphaPremultiplied = NO;
            alphaFirst = NO;
            break;
        case kCGImageAlphaFirst:
            alphaPremultiplied = NO;
            alphaFirst = YES;
            break;
        case kCGImageAlphaPremultipliedLast:
            alphaPremultiplied = YES;
            alphaFirst = NO;
            break;
        case kCGImageAlphaPremultipliedFirst:
            alphaPremultiplied = YES;
            alphaFirst = YES;
            break;
        case kCGImageAlphaNoneSkipLast:
            alphaPremultiplied = NO;
            alphaFirst = NO;
            break;
        case kCGImageAlphaNoneSkipFirst:
            alphaPremultiplied = NO;
            alphaFirst = YES;
            break;
        default:
            NSAssert(NO, @"");
            break;
    }
    
    int alphaIndex = byteOrderLittle ? (alphaFirst ? 1 : 0) : (alphaFirst ? 0 : 1);
    
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MTIAlphaTypeHandlingRule *rule = [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied),@(MTIAlphaTypeNonPremultiplied),@(MTIAlphaTypeAlphaIsOne)] outputAlphaType:MTIAlphaTypeNonPremultiplied];
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"rgToMonochrome"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:rule];
    });
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:image.dimensions pixelFormat:MTLPixelFormatBGRA8Unorm];
    MTIRenderCommand *renderCommand = [[MTIRenderCommand alloc] initWithKernel:kernel
                                                                      geometry:flip ?
                                       [MTIVertices verticallyFlippedSquareVerticesForRect:CGRectMake(-1, -1, 2, 2)] :
                                       [MTIVertices squareVerticesForRect:CGRectMake(-1, -1, 2, 2)]
                                                                        images:@[image]
                                                                    parameters:@{@"alphaChannelIndex": @(alphaIndex),
                                                                                 @"unpremultiplyAlpha": @((bool)alphaPremultiplied),
                                                                                 @"convertSRGBToLinear": @((bool)sRGBToLinear)}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[renderCommand]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (MTIImage *)imageFromRChannelMonochromeImage:(MTIImage *)image sRGBToLinear:(BOOL)sRGBToLinear flip:(BOOL)flip {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"rToMonochrome"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
    });
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:image.dimensions pixelFormat:MTLPixelFormatBGRA8Unorm];
    MTIRenderCommand *renderCommand = [[MTIRenderCommand alloc] initWithKernel:kernel
                                                                      geometry:flip ?
                                       [MTIVertices verticallyFlippedSquareVerticesForRect:CGRectMake(-1, -1, 2, 2)] :
                                       [MTIVertices squareVerticesForRect:CGRectMake(-1, -1, 2, 2)]
                                                                        images:@[image]
                                                                    parameters:@{@"invert": @((bool)false),
                                                                                 @"convertSRGBToLinear": @((bool)sRGBToLinear)}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[renderCommand]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end

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

- (instancetype)initWithMTKTextureLoaderIncompatibleCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options isOpaque:(BOOL)isOpaque {
    //Handle monochrome image.
    CGColorSpaceRef sourceColorspace = CGImageGetColorSpace(cgImage);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
    size_t componentsPerPixel = bitsPerPixel/bitsPerComponent;
    
    static NSDictionary<NSString *, NSNumber *> *colorspaceSRGBTable;
    static NSDictionary<MTKTextureLoaderOrigin, NSNumber *> *flipTable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorspaceSRGBTable = @{(id)kCGColorSpaceGenericGrayGamma2_2: @YES,
                                (id)kCGColorSpaceExtendedGray: @YES,
                                (id)kCGColorSpaceLinearGray: @NO,
                                (id)kCGColorSpaceExtendedLinearGray: @NO};
        flipTable = @{MTKTextureLoaderOriginTopLeft: @NO,
                      MTKTextureLoaderOriginBottomLeft: @YES,
                      MTKTextureLoaderOriginFlippedVertically: @YES};
    });
    NSNumber *sRGBValue = colorspaceSRGBTable[(__bridge_transfer id)CGColorSpaceCopyName(sourceColorspace)];
    if (CGColorSpaceGetModel(sourceColorspace) == kCGColorSpaceModelMonochrome &&
        bitsPerComponent == 8 &&
        (componentsPerPixel == 1 || componentsPerPixel == 2) &&
        sRGBValue) {
        BOOL sRGB = [sRGBValue boolValue];
        
        id sRGBOption = options[MTKTextureLoaderOptionSRGB];
        if (sRGBOption) {
            sRGB = [sRGBOption boolValue];
        }
        
        MTKTextureLoaderOrigin originOption = options[MTKTextureLoaderOptionOrigin];
        BOOL flip = NO;
        if (originOption) {
            flip = [flipTable[originOption] boolValue];
        }
        
        CGImageAlphaInfo alphaInfo = CGImageGetBitmapInfo(cgImage) & kCGBitmapAlphaInfoMask;
        CGImageByteOrderInfo byteOrderInfo = CGImageGetBitmapInfo(cgImage) & kCGBitmapByteOrderMask;
        size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
        CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
        CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
        NSData *bitmapData = (__bridge_transfer NSData *)dataRef;
        if (componentsPerPixel == 1) {
            MTIImage *rImage = [[MTIImage alloc] initWithPromise:[[MTIBitmapDataImagePromise alloc] initWithBitmapData:bitmapData width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) bytesPerRow:bytesPerRow pixelFormat:MTLPixelFormatR8Unorm alphaType:MTIAlphaTypeAlphaIsOne]];
            return [[MTIImage imageFromRChannelMonochromeImage:rImage sRGBToLinear:sRGB flip:flip] imageWithCachePolicy:MTIImageCachePolicyPersistent];
        } else {
            MTIImage *rgImage = [[MTIImage alloc] initWithPromise:[[MTIBitmapDataImagePromise alloc] initWithBitmapData:bitmapData width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) bytesPerRow:bytesPerRow pixelFormat:MTLPixelFormatRG8Unorm alphaType:MTIAlphaTypeAlphaIsOne]];
            return [[MTIImage imageFromRGChannelMonochromeImage:rgImage alphaInfo:alphaInfo byteOrderInfo:byteOrderInfo sRGBToLinear:sRGB flip:flip] imageWithCachePolicy:MTIImageCachePolicyPersistent];
        }
    }
    
    //Fallback: Redraw `cgImage`.
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, CGImageGetWidth(cgImage) * 4, colorspace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorspace);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGImageRef redrawedImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    @MTI_DEFER {
        CGImageRelease(redrawedImage);
    };
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:redrawedImage options:options alphaType:isOpaque ? MTIAlphaTypeAlphaIsOne : MTIAlphaTypePremultiplied] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
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
    if (MTIMTKTextureLoaderCanDecodeImage(cgImage)) {
        return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage options:options alphaType:preferredAlphaType] samplerDescriptor:MTISamplerDescriptor.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
    } else {
        return [self initWithMTKTextureLoaderIncompatibleCGImage:cgImage options:options isOpaque:isOpaque];
    }
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
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL properties:properties options:options alphaType:MTIPreferredAlphaTypeForImageWithProperties(properties)];
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
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL properties:properties options:options alphaType:alphaType];
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
