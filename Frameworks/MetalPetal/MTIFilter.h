//
//  MTIFilter.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIFilterPassthroughVertexFunctionName;
FOUNDATION_EXPORT NSString * const MTIFilterPassthroughFragmentFunctionName;

@class MTIImage, MTIFilterFunctionDescriptor;

@interface MTIFilter : NSObject

@property (nonatomic, strong, readonly, nullable) MTIImage *outputImage;

- (instancetype)initWithVertexFunctionDescriptor:(MTIFilterFunctionDescriptor *)vertexFunctionDescriptor
                      fragmentFunctionDescriptor:(MTIFilterFunctionDescriptor *)fragmentFunctionDescriptor NS_DESIGNATED_INITIALIZER;

- (MTIImage *)applyWithInputImages:(NSArray<MTIImage *> *)images
                        parameters:(NSArray *)parameters
           outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor;

@end

NS_ASSUME_NONNULL_END
