//
//  MTIDrawableRendering.h
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIDrawableRenderingRequest;

@protocol MTIDrawableProvider <NSObject>

- (nullable id<MTLDrawable>)drawableForRequest:(MTIDrawableRenderingRequest *)request;

- (nullable MTLRenderPassDescriptor *)renderPassDescriptorForRequest:(MTIDrawableRenderingRequest *)request;

@end

typedef NS_ENUM(NSUInteger, MTIDrawableRenderingResizingMode) {
    MTIDrawableRenderingResizingModeScale,
    MTIDrawableRenderingResizingModeAspect,
    MTIDrawableRenderingResizingModeAspectFill
};

@interface MTIDrawableRenderingRequest : NSObject

@property (nonatomic, copy, readonly) NSUUID *identifier;

@property (nonatomic, weak) id<MTIDrawableProvider> drawableProvider;

@property (nonatomic) MTIDrawableRenderingResizingMode resizingMode;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTKView (MTIDrawableProvider) <MTIDrawableProvider>

@end

NS_ASSUME_NONNULL_END
