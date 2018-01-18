//
//  MTIMPSBoxBlurFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#import "MTIFilter.h"
#import <simd/simd.h>

@interface MTIMPSBoxBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) simd_int2 size;

@end
