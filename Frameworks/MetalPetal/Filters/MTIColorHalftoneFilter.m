//
//  MTIColorHalftoneFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import "MTIColorHalftoneFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector.h"

@interface MTIColorHalftoneFilter ()

@property (nonatomic, readonly) simd_float2 center;

@end

@implementation MTIColorHalftoneFilter

- (instancetype)init {
    if (self = [super init]) {
        _radius = 20;
        _angles = simd_make_float4(0, 0, 0, 0);
        _mode = MTIColorHalftoneModeCMYK;
        _center = simd_make_float2(0, 0);
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"colorHalftone"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"mode": @((int)self.mode),
             @"radius": @(self.radius),
             @"angles": [[MTIVector alloc] initWithFloat4:self.angles],
             @"center": [[MTIVector alloc] initWithFloat2:self.center]};
}

@end
