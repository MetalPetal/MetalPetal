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

@interface MTIImage : NSObject <NSCopying>

@property (nonatomic,readonly) CGRect extent;

@property (nonatomic,copy,readonly) MTLSamplerDescriptor *samplerDescriptor;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor;

- (instancetype)imageWithSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor;

@end

NS_ASSUME_NONNULL_END
