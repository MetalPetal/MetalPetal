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

@class MTIImage, MTIImageRenderingContext, MTIFilterFunctionDescriptor, MTITextureDescriptor, MTIImagePromiseRenderTarget;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (nullable MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError **)error;

- (NSArray<MTIImage *> *)dependencies;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

@end

@interface MTITexturePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithTexture:(id<MTLTexture>)texture;

@end

@interface MTICIImagePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithCIImage:(CIImage *)ciImage;

@end

@interface MTITextureDescriptorPromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor;

@end


NS_ASSUME_NONNULL_END

