//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIImageRenderingContext, MTIFilterFunctionDescriptor, MTITextureDescriptor, MTIImagePromiseRenderTarget;

struct MTITextureDimensions {
    NSUInteger width;
    NSUInteger height;
    NSUInteger depth;
};
typedef struct MTITextureDimensions MTITextureDimensions;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic,readonly) MTITextureDimensions dimensions;

- (nullable MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError **)error;

- (NSArray<MTIImage *> *)dependencies;

@end

#pragma mark - Promises

@interface MTIImageURLPromise : NSObject <MTIImagePromise>

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary *)options;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

@end

@interface MTITexturePromise : NSObject <MTIImagePromise>

- (instancetype)initWithTexture:(id<MTLTexture>)texture;

@end

@interface MTICIImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCIImage:(CIImage *)ciImage;

@end

@interface MTITextureDescriptorPromise : NSObject <MTIImagePromise>

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor;

@end


NS_ASSUME_NONNULL_END

