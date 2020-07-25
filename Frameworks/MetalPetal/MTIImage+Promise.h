//
//  MTIImage-Private.h
//  Pods
//
//  Created by YuAo on 14/07/2017.
//
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIImage.h>
#else
#import "MTIImage.h"
#endif
@protocol MTIImagePromise;

NS_ASSUME_NONNULL_BEGIN

@interface MTIImage (Promise)

@property (nonatomic,copy,readonly) id<MTIImagePromise> promise;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor cachePolicy:(MTIImageCachePolicy)cachePolicy;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise cachePolicy:(MTIImageCachePolicy)cachePolicy;

@end

NS_ASSUME_NONNULL_END
