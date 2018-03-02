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

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

- (nullable MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError **)error NS_SWIFT_NAME(makeTexture(descriptor:));

/// Frees as many textures from the pool as possible.
- (void)flush;

/*!
 @property allocatedSize
 @abstrace The size in bytes occupied by idle resources
 */
@property (nonatomic, readonly) NSUInteger idleResourceSize NS_AVAILABLE(10_13, 11_0);

@property (nonatomic, readonly) NSUInteger idleResourceCount;

@end

NS_ASSUME_NONNULL_END
