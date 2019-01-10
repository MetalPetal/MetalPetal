//
//  MTKTextureLoaderExtension.m
//  Pods
//
//  Created by Yu Ao on 06/12/2017.
//

#import "MTITextureLoaderForiOS9.h"
#import "MTIDefer.h"
#import "MTICVMetalTextureCache.h"

#if TARGET_OS_IPHONE

NSString * const MTITextureLoaderForiOS9ErrorDomain = @"MTITextureLoaderForiOS9ErrorDomain";

typedef NS_ERROR_ENUM(MTITextureLoaderForiOS9ErrorDomain, MTITextureLoaderForiOS9Error) {
    MTITextureLoaderForiOS9ErrorCannotDecodeImage = 1001,
    MTITextureLoaderForiOS9ErrorInvaildTextureCache = 1002,
    MTITextureLoaderForiOS9ErrorFailedToAllocateMemory = 1003,
    MTITextureLoaderForiOS9ErrorFeatureNotSupported = 1004,
    MTITextureLoaderForiOS9ErrorCannotRenderImage = 1005
};

@interface MTITextureLoaderForiOS9WithImageOrientationFix ()

@property (nonatomic, strong, readonly) id <MTLDevice> device;

@property (nonatomic, strong, readonly) MTICVMetalTextureCache *textureCache;

@end

@implementation MTITextureLoaderForiOS9WithImageOrientationFix

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        NSAssert(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_9_x_Max, @"MTITextureLoaderForiOS9WithImageOrientationFix is designed for iOS 9 only.");
        _device = device;
        _textureCache = [[MTICVMetalTextureCache alloc] initWithDevice:device cacheAttributes:nil textureAttributes:nil error:nil];
    }
    return self;
}

+ (instancetype)newTextureLoaderWithDevice:(id<MTLDevice>)device {
    return [[MTITextureLoaderForiOS9WithImageOrientationFix alloc] initWithDevice:device];
}

- (id<MTLTexture>)newTextureWithCGImage:(CGImageRef)cgImage options:(NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError *__autoreleasing  _Nullable *)error {
    NSCParameterAssert(cgImage);
    
    if (!_textureCache) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorInvaildTextureCache userInfo:nil];
        }
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}}, &pixelBuffer);
    if (!pixelBuffer) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorFailedToAllocateMemory userInfo:nil];
        }
        return nil;
    }
    
    @MTI_DEFER {
        CVPixelBufferRelease(pixelBuffer);
    };
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    if (!colorspace) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorCannotRenderImage userInfo:nil];
        }
        return nil;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CGContextRef context = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer), CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, CVPixelBufferGetBytesPerRow(pixelBuffer), colorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorspace);
    if (!context) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorCannotRenderImage userInfo:nil];
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    // Handle sRGB
    MTLPixelFormat pixelFormat;
    if ([options[MTKTextureLoaderOptionSRGB] boolValue]) {
        pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    } else {
        pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) mipmapped:NO];
    id<MTICVMetalTexture> cvMetalTexture = [_textureCache newTextureWithCVImageBuffer:pixelBuffer textureDescriptor:textureDescriptor planeIndex:0 error:error];
    return cvMetalTexture.texture;
}

- (id<MTLTexture>)newTextureWithContentsOfURL:(NSURL *)URL options:(NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError *__autoreleasing  _Nullable *)error {
    NSDictionary *imageSourceOptions = @{(id)kCGImageSourceShouldCache: @NO,
                                         (id)kCGImageSourceShouldCacheImmediately: @NO,
                                         (id)kCGImageSourceShouldAllowFloat: @YES};
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)URL, (CFDictionaryRef)imageSourceOptions);
    if (imageSource) {
        if (CGImageSourceGetCount(imageSource) > 0) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)imageSourceOptions);
            CFRelease(imageSource);
            if (!image) {
                if (error) {
                    *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorCannotDecodeImage userInfo:nil];
                }
                return nil;
            }
            id<MTLTexture> texture = [self newTextureWithCGImage:image options:options error:error];
            CGImageRelease(image);
            return texture;
        } else {
            CFRelease(imageSource);
            if (error) {
                *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorCannotDecodeImage userInfo:nil];
            }
            return nil;
        }
    } else {
        if (error) {
            *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorCannotDecodeImage userInfo:nil];
        }
        return nil;
    }
}

- (nullable id<MTLTexture>)newTextureWithName:(nonnull NSString *)name scaleFactor:(CGFloat)scaleFactor bundle:(nullable NSBundle *)bundle options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if (error) {
        *error = [[NSError alloc] initWithDomain:MTITextureLoaderForiOS9ErrorDomain code:MTITextureLoaderForiOS9ErrorFeatureNotSupported userInfo:nil];
    }
    return nil;
}

@end

#endif
