//
//  MTIPixelFormat.h
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//


#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT MTLPixelFormat const MTIPixelFormatUnspecified;   //aliased to MTLPixelFormatInvalid

@interface NSNumber (MTIPixelFormat)

- (MTLPixelFormat)MTLPixelFormatValue;

@end

NS_ASSUME_NONNULL_END

