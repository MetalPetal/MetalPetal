//
//  MTIPixellateFilter.m
//  Pods
//
//  Created by Yu Ao on 08/01/2018.
//

#import "MTIPixellateFilter.h"
#import "MTIFunctionDescriptor.h"

@implementation MTIPixellateFilter

- (instancetype)init {
    if (self = [super init]) {
        _fractionalWidthOfAPixel = 0.05;
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"pixellateEffect"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"fractionalWidthOfAPixel": @(self.fractionalWidthOfAPixel)};
}

@end
