//
//  MTITexturePool.h
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTITextureDescriptor;

@interface MTIReusableTexture : NSObject

@property (nonatomic,strong,nullable) id<MTLTexture> texture;

- (void)retainTexture;

- (void)releaseTexture;

@end

@interface MTITexturePool : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor;

@end

NS_ASSUME_NONNULL_END
