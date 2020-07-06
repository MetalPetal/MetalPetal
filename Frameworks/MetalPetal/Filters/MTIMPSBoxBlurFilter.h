//
//  MTIMPSBoxBlurFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//
#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

__attribute__((objc_subclassing_restricted))
@interface MTIMPSBoxBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) simd_int2 size;

@end
