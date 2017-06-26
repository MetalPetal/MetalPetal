//
//  MTIContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIContext : NSObject

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(__autoreleasing NSError **)error;

- (nullable id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(__autoreleasing NSError **)error;

@end

NS_ASSUME_NONNULL_END
