//
//  MTIImage.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTISamplerDescriptor;

typedef NS_ENUM(NSInteger, MTIImageCachePolicy) {
    MTIImageCachePolicyTransient,
    MTIImageCachePolicyPersistent
};

@interface MTIImage : NSObject <NSCopying>

@property (nonatomic,readonly) MTIImageCachePolicy cachePolicy;

@property (nonatomic,readonly) CGRect extent;

@property (nonatomic,readonly) CGSize size;

@property (nonatomic,copy,readonly) MTISamplerDescriptor *samplerDescriptor;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor;

@end

@interface MTIImage (Creation)

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

- (instancetype)initWithTexture:(id<MTLTexture>)texture;

- (instancetype)initWithCIImage:(CIImage *)ciImage;

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor;

@end


NS_ASSUME_NONNULL_END
