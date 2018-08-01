//
//  MTIPixellateFilter.m
//  Pods
//
//  Created by Yu Ao on 08/01/2018.
//

#import "MTIPixellateFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector.h"

@implementation MTIPixellateFilter

- (instancetype)init {
    if (self = [super init]) {
        _scale = CGSizeMake(16.0, 16.0);
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"pixellate"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"scale": [MTIVector vectorWithCGSize:self.scale]};
}

@end
