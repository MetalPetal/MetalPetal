//
//  MTITextureLoader.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/10.
//

#import "MTITextureLoader.h"

#pragma mark - MTKTextureLoader

@implementation MTKTextureLoader (MTITextureLoader)

+ (instancetype)newTextureLoaderWithDevice:(id<MTLDevice>)device {
    return [[MTKTextureLoader alloc] initWithDevice:device];
}

@end

#pragma mark - MTIDefaultTextureLoader

#import <CoreImage/CoreImage.h>
#import "MTICVMetalTextureCache.h"
#import "MTICVMetalIOSurfaceBridge.h"
#import "MTIImageProperties.h"
#import "MTIDefer.h"
#import "MTITextureDescriptor.h"
#import "MTIError.h"

@interface MTIDefaultTextureLoader ()

@property (nonatomic, strong) MTKTextureLoader *internalLoader;
@property (nonatomic, strong) id<MTICVMetalTextureBridging> cvMetalTextureBridging;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) id<MTLDevice> device;

@end

@implementation MTIDefaultTextureLoader

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        _internalLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        NSError *error = nil;
        _cvMetalTextureBridging = [MTICVMetalIOSurfaceBridge newCoreVideoMetalTextureBridgeWithDevice:device error:&error];
        _error = error;
    }
    return self;
}

+ (instancetype)newTextureLoaderWithDevice:(id<MTLDevice>)device {
    return [[MTIDefaultTextureLoader alloc] initWithDevice:device];
}

- (nullable id<MTLTexture>)newTextureWithCVPixelBufferFromCGImage:(CGImageRef)cgImage
                                                       properties:(MTIImageProperties *)properties
                                                          options:(NSDictionary<MTKTextureLoaderOption,id> *)options
                                                            error:(NSError * _Nullable __autoreleasing *)error {
    if (_error) {
        if (error) {
            *error = _error;
        }
        return nil;
    } else {
        CVPixelBufferRef pixelBuffer = nil;
        CVPixelBufferCreate(kCFAllocatorDefault,
                            properties.displayWidth,
                            properties.displayHeight,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                            &pixelBuffer);
        if (!pixelBuffer) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorFailedToCreateCVPixelBuffer, nil);
            }
            return nil;
        }
        
        @MTI_DEFER {
            CVPixelBufferRelease(pixelBuffer);
        };
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer),
                                                       properties.displayWidth,
                                                       properties.displayHeight,
                                                       8,
                                                       CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                       colorSpace,
                                                       kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        if (!cgContext) {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            if (error) {
                *error = MTIErrorCreate(MTIErrorTextureLoaderFailedToCreateCGContext, nil);
            }
            return nil;
        }
        
        BOOL shouldFallbackToMTKTextureLoader = NO;
        if ([options[MTKTextureLoaderOptionAllocateMipmaps] boolValue] || [options[MTKTextureLoaderOptionGenerateMipmaps] boolValue] || options[MTKTextureLoaderOptionCubeLayout]) {
            shouldFallbackToMTKTextureLoader = YES;
        }
        
        #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
        //Workaround for #64. See https://github.com/MetalPetal/MetalPetal/issues/64
        if (![_device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1]) {
            shouldFallbackToMTKTextureLoader = YES;
        }
        #endif
        
        if (shouldFallbackToMTKTextureLoader) {
            // We do not currently support these features, so fallback to `MTKTextureLoader`. This may degrade texture loading performance. (Loading a CVPixelBuffer is much faster)
            CIImage *placeholder = [[CIImage imageWithColor:CIColor.blackColor] imageByCroppingToRect:CGRectMake(0, 0, properties.pixelWidth, properties.pixelHeight)];
            CGContextConcatCTM(cgContext, [placeholder imageTransformForOrientation:properties.orientation]);
            CGContextDrawImage(cgContext, CGRectMake(0, 0, properties.pixelWidth, properties.pixelHeight), cgImage);
            CGImageRef sanitizedCGImage = CGBitmapContextCreateImage(cgContext);
            CGContextRelease(cgContext);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            
            if (!sanitizedCGImage) {
                if (error) {
                    *error = MTIErrorCreate(MTIErrorTextureLoaderFailedToCreateCGImage, nil);
                }
                return nil;
            }
            
            @MTI_DEFER {
                CGImageRelease(sanitizedCGImage);
            };
            
            return [_internalLoader newTextureWithCGImage:sanitizedCGImage options:options error:error];
        } else {
            CIImage *placeholder = [[CIImage imageWithColor:CIColor.blackColor] imageByCroppingToRect:CGRectMake(0, 0, properties.pixelWidth, properties.pixelHeight)];
            if (options[MTKTextureLoaderOptionOrigin] == MTKTextureLoaderOriginBottomLeft || options[MTKTextureLoaderOptionOrigin] == MTKTextureLoaderOriginFlippedVertically) {
                CGContextConcatCTM(cgContext, CGAffineTransformMake(1, 0, 0, -1, 0, properties.displayHeight));
            }
            CGContextConcatCTM(cgContext, [placeholder imageTransformForOrientation:properties.orientation]);
            CGContextDrawImage(cgContext, CGRectMake(0, 0, properties.pixelWidth, properties.pixelHeight), cgImage);
            CGContextRelease(cgContext);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            
            BOOL useSRGBTexture = NO;
            if (options[MTKTextureLoaderOptionSRGB] == nil) {
                useSRGBTexture = YES;
            } else {
                useSRGBTexture = [options[MTKTextureLoaderOptionSRGB] boolValue];
            }
            MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:useSRGBTexture ? MTLPixelFormatBGRA8Unorm_sRGB : MTLPixelFormatBGRA8Unorm width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
            if (options[MTKTextureLoaderOptionTextureUsage]) {
                textureDescriptor.usage = [options[MTKTextureLoaderOptionTextureUsage] unsignedIntegerValue];
            } else {
                textureDescriptor.usage = MTLTextureUsageShaderRead;
            }
            if (options[MTKTextureLoaderOptionTextureStorageMode]) {
                textureDescriptor.storageMode = [options[MTKTextureLoaderOptionTextureStorageMode] unsignedIntegerValue];
            }
            if (options[MTKTextureLoaderOptionTextureCPUCacheMode]) {
                textureDescriptor.cpuCacheMode = [options[MTKTextureLoaderOptionTextureCPUCacheMode] unsignedIntegerValue];
            }
            return [_cvMetalTextureBridging newTextureWithCVImageBuffer:pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:error].texture;
        }
    }
}

- (BOOL)prefersCVPixelBufferLoaderForImageWithProperties:(MTIImageProperties *)properties {
    if (!properties) {
        return NO;
    }
    if (properties.byteOrderInfo == kCGImageByteOrder32Little &&
        CGColorSpaceGetNumberOfComponents(properties.colorSpace) == 3 &&
        CGColorSpaceGetModel(properties.colorSpace) == kCGColorSpaceModelRGB &&
        properties.bitsPerComponent == 8 &&
        [CFBridgingRelease(CGColorSpaceCopyPropertyList(properties.colorSpace)) isEqual:(id)kCGColorSpaceSRGB]
        ) {
        return NO;
    }
    return YES;
}

- (nullable id<MTLTexture>)newTextureWithCGImage:(nonnull CGImageRef)cgImage options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    MTIImageProperties *properties = [[MTIImageProperties alloc] initWithCGImage:cgImage];
    if ([self prefersCVPixelBufferLoaderForImageWithProperties:properties]) {
        return [self newTextureWithCVPixelBufferFromCGImage:cgImage properties:properties options:options error:error];
    } else {
        return [_internalLoader newTextureWithCGImage:cgImage options:options error:error];
    }
}

- (nullable id<MTLTexture>)newTextureWithContentsOfURL:(nonnull NSURL *)URL options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSDictionary *imageSourceOptions = @{(id)kCGImageSourceShouldCache: @NO,
                                         (id)kCGImageSourceShouldCacheImmediately: @NO,
                                         (id)kCGImageSourceShouldAllowFloat: @YES};
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)URL, (__bridge CFDictionaryRef)imageSourceOptions);
    if (source) {
        @MTI_DEFER { CFRelease(source); };
        if (CGImageSourceGetCount(source) > 0) {
            MTIImageProperties *properties = [[MTIImageProperties alloc] initWithImageSource:source index:0];
            if ([self prefersCVPixelBufferLoaderForImageWithProperties:properties]) {
                CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)imageSourceOptions);
                if (cgImage) {
                    @MTI_DEFER { CGImageRelease(cgImage); };
                    return [self newTextureWithCVPixelBufferFromCGImage:cgImage properties:properties options:options error:error];
                }
            }
        }
    }
    return [_internalLoader newTextureWithContentsOfURL:URL options:options error:error];
}

- (nullable id<MTLTexture>)newTextureWithMDLTexture:(nonnull MDLTexture *)texture options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [_internalLoader newTextureWithMDLTexture:texture options:options error:error];
}

- (nullable id<MTLTexture>)newTextureWithName:(nonnull NSString *)name scaleFactor:(CGFloat)scaleFactor bundle:(nullable NSBundle *)bundle options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [_internalLoader newTextureWithName:name scaleFactor:scaleFactor bundle:bundle options:options error:error];
}

@end
