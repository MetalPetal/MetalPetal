//
//  MTIVibranceFilter.m
//  MetalPetal
//
//  Created by 杨乃川 on 2017/11/6.
//

#import "MTIVibranceFilter.h"
#import "MTIVector.h"
#import "MTIShaderTypes.h"

@implementation MTIVibranceFilter

+ (NSString *)fragmentFunctionName {
    return @"vibranceAdjust";
}

- (NSDictionary<NSString *,id> *)parameters {
    simd_float4 vector = (simd_float4){
         3 * _amount,
        -9.0/2.0 * _amount * _amount - 3.0/2.0 * _amount,
        9.0/2.0 * _amount * _amount * _amount - _amount/2.0,
        -9.0/2.0 * _amount * _amount * _amount + 9.0/2.0 * _amount * _amount - _amount
    };
    return @{
             @"amount": @(_amount),
             @"vibranceVector": [[MTIVector alloc] initWithFloat4:vector],
             @"avoidsSaturatingSkinTones": @(_avoidsSaturatingSkinTones)
             };
}

@end
