//
//  MTICVMetalTextureBridging.h
//  Pods
//
//  Created by Yu Ao on 2018/10/10.
//

#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTICVMetalTexture <NSObject>

@property (nonatomic, readonly) id<MTLTexture> texture;

@end

@protocol MTICVMetalTextureBridging <NSObject>

+ (nullable instancetype)newCoreVideoMetalTextureBridgeWithDevice:(id<MTLDevice>)device error:(NSError **)error NS_SWIFT_NAME(makeCoreVideoMetalTextureBridge(with:));

- (nullable id<MTICVMetalTexture>)newTextureWithCVImageBuffer:(CVImageBufferRef)imageBuffer
                                            textureDescriptor:(MTLTextureDescriptor *)textureDescriptor
                                                   planeIndex:(size_t)planeIndex
                                                        error:(NSError **)error NS_SWIFT_NAME(makeTexture(with:textureDescriptor:planeIndex:));

- (void)flushCache;

@end

NS_ASSUME_NONNULL_END
