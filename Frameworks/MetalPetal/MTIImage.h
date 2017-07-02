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

@property (nonatomic,copy,readonly) id<MTIImagePromise> promise;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor;

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor;

@end

NS_ASSUME_NONNULL_END
