//
//  MTIFilter.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIFilter : NSObject

@property (nonatomic, strong, readonly, nullable) MTIImage *inputImage;

@property (nonatomic, strong, readonly, nullable) MTIImage *outputImage;

@end

NS_ASSUME_NONNULL_END
