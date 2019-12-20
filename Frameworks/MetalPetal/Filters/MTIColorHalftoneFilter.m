//
//  MTIColorHalftoneFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import "MTIColorHalftoneFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector+SIMD.h"

@implementation MTIColorHalftoneFilter

- (instancetype)init {
    if (self = [super init]) {
        _scale = 20;
        _angles = simd_make_float4(M_PI_4, M_PI_4, M_PI_4, 0);
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"colorHalftone"];
}

- (NSDictionary<NSString *,id> *)parameters {
    BOOL allAnglesAreEqual = NO;
    if (self.angles.x == self.angles.y && self.angles.y == self.angles.z) {
        allAnglesAreEqual = YES;
    }
    return @{@"scale": @(MAX(self.scale, 1.0f)),
             @"angles": [MTIVector vectorWithFloat4:self.angles],
             @"singleAngleMode": @(allAnglesAreEqual)};
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule;
}

@end
