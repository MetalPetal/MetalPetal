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

/// A reusable texture from a texture pool.
@interface MTIReusableTexture : NSObject

/// Returns the underlaying texture. When a reusable texture's texture retain count reachs zero, this method will return nil.
@property (atomic,strong,nullable,readonly) id<MTLTexture> texture;

/// Increase the texture's texture retain count. If the retain operation failed, i.e. the texture is already been reused and no longer valid, this method will return `NO`.
- (BOOL)retainTexture;

/// Decrease the texture's texture retain count. When the retain count reaches zero, returns the underlaying texture to the texture pool.
- (void)releaseTexture;

@end

/// A texture pool which allocates and reuses metal textures.
@interface MTITexturePool : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

- (nullable MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError **)error NS_SWIFT_NAME(makeTexture(descriptor:));

/// Frees as many textures from the pool as possible.
- (void)flush;

/// The size in bytes occupied by idle resources.
@property (nonatomic, readonly) NSUInteger idleResourceSize NS_AVAILABLE(10_13, 11_0);

/// The count of idle resources.
@property (nonatomic, readonly) NSUInteger idleResourceCount;

@end

NS_ASSUME_NONNULL_END
