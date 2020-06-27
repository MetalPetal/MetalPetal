//
//  MTIMPSBoxBlurFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//
#import <simd/simd.h>
#import <MTIFilter.h>

__attribute__((objc_subclassing_restricted))
@interface MTIMPSBoxBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) simd_int2 size;

@end
