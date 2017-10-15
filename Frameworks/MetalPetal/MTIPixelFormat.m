//
//  MTIPixelFormat.m
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//

#import "MTIPixelFormat.h"
#import <AssertMacros.h>

MTLPixelFormat const MTIPixelFormatUnspecified = MTLPixelFormatInvalid;

@implementation NSNumber (MTIPixelFormat)

- (MTLPixelFormat)MTLPixelFormatValue {
    __Check_Compile_Time(__builtin_types_compatible_p(MTLPixelFormat, NSUInteger));
    return [self unsignedIntegerValue];
}

@end
