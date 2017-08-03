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

///Returns the underlining texture. When a reusable texture's texture retain count reachs zero, this method will return nil.
@property (atomic,strong,nullable,readonly) id<MTLTexture> texture;

///Increase the texture's texture retain count. If the retain operation failed, i.e. the texture is already been reused and no longer valid, this method will return `NO`.
- (BOOL)retainTexture;

- (void)releaseTexture;

@end

@interface MTITexturePool : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor;

@end

NS_ASSUME_NONNULL_END
