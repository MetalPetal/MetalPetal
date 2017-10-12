//
//  MTIFilter.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIFilterPassthroughVertexFunctionName;
FOUNDATION_EXPORT NSString * const MTIFilterPassthroughFragmentFunctionName;

@class MTIImage;

@protocol MTIFilter <NSObject>

@property (nonatomic) MTLPixelFormat outputPixelFormat; //Default: MTIPixelFormatUnspecified aka MTLPixelFormatInvalid

@property (nonatomic, readonly, nullable) MTIImage *outputImage;

// return property names
// * property in NSSet will be coverted as shader parameter
// * required protocal method
+ (NSSet <NSString *> *)inputParameterKeys;

@end

NS_ASSUME_NONNULL_END
