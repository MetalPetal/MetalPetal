//
//  MTIRenderPipelineOutputDescriptor.h
//  Pods
//
//  Created by YuAo on 18/11/2017.
//

#import <Metal/Metal.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTITextureDimensions.h>
#else
#import "MTITextureDimensions.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIRenderPassOutputDescriptor: NSObject <NSCopying>

@property (nonatomic,readonly) MTITextureDimensions dimensions;

@property (nonatomic,readonly) MTLPixelFormat pixelFormat;

@property (nonatomic,readonly) MTLLoadAction loadAction;

@property (nonatomic,readonly) MTLStoreAction storeAction;

@property (nonatomic,readonly) MTLClearColor clearColor;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction storeAction:(MTLStoreAction)storeAction;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat clearColor:(MTLClearColor)clearColor loadAction:(MTLLoadAction)loadAction storeAction:(MTLStoreAction)storeAction NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToOutputDescriptor:(MTIRenderPassOutputDescriptor *)object;

@end

NS_ASSUME_NONNULL_END
