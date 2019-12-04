//
//  MTIBulgeDistortionFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/14.
//

#import "MTIBulgeDistortionFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector+SIMD.h"

@implementation MTIBulgeDistortionFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"bulgeDistortion"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"center": [MTIVector vectorWithFloat2:_center],
             @"radius": @(_radius),
             @"scale": @(_scale)};
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule;
}

@end
