//
//  MTIRoundCornerFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/20.
//

#import <simd/simd.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIRoundCornerFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) simd_float4 radius; //lt rt rb lb

@end

NS_ASSUME_NONNULL_END
