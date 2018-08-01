//
//  MTIDotScreenFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#import "MTIDotScreenFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector+SIMD.h"
#import "MTIColor.h"

@implementation MTIDotScreenFilter

- (instancetype)init {
    if (self = [super init]) {
        _angle = M_PI_4;
        _scale = 12.0;
        _grayColorTransform = MTIGrayColorTransformDefault;
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"dotScreen"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"angle": @(self.angle),
             @"scale": @(self.scale),
             @"grayColorTransform": [MTIVector vectorWithFloat3:self.grayColorTransform]};
}

@end
