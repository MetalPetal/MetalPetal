//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIImageRenderingContext, MTIFilterFunctionDescriptor;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic,copy,readonly) MTLTextureDescriptor *outputTextureDescriptor;

- (nullable id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError **)error;

@end

@interface MTIPixelBufferImagePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTLTextureDescriptor *outputTextureDescriptor;

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTLTextureDescriptor *outputTextureDescriptor;

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

@end

NS_ASSUME_NONNULL_END

