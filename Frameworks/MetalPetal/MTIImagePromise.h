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

@class MTIImage, MTIImageRenderingContext, MTIFilterFunctionDescriptor, MTITextureDescriptor;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (nullable id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError **)error;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

@end

@interface MTITexturePromise : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithTexture:(id<MTLTexture>)texture;

@end

NS_ASSUME_NONNULL_END

