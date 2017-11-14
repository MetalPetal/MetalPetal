//
//  MTIMask.m
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import "MTIMask.h"

@implementation MTIMask

- (instancetype)initWithContent:(MTIImage *)content component:(MTIColorComponent)component mode:(MTIMaskMode)mode {
    if (self = [super init]) {
        _content = content;
        _component = component;
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithContent:(MTIImage *)content {
    return [self initWithContent:content component:MTIColorComponentRed mode:MTIMaskModeNormal];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
