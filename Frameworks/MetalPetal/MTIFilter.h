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

@class MTIImage;

@protocol MTIFilter <NSObject>

@property (nonatomic, readonly, nullable) MTIImage *outputImage;

@end

NS_ASSUME_NONNULL_END
