//
//  MTIRoundCornerFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/20.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#import <MetalPetal/MTICorner.h>
#else
#import "MTIFilter.h"
#import "MTICorner.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIRoundCornerFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) MTICornerRadius cornerRadius;
@property (nonatomic) MTICornerCurve cornerCurve;

@property (nonatomic) simd_float4 radius __attribute__((deprecated("Use `cornerRadius` and `cornerCurve` instead.")));

@end

NS_ASSUME_NONNULL_END
