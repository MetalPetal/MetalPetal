//
//  MTIImageRenderingContext+Internal.h
//  MetalPetal
//
//  Created by Yu Ao on 2020/1/20.
//

#import <Foundation/Foundation.h>
#import "MTIImageRenderingContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MTIImagePromiseResolution <NSObject>

@property (nonatomic,readonly) id<MTLTexture> texture;

- (void)markAsConsumedBy:(id)consumer;

@end

@interface MTIImageRenderingContext (Internal)

- (instancetype)initWithContext:(MTIContext *)context;

- (nullable id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
