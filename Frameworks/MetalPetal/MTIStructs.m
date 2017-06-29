//
//  MTIStructs.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIStructs.h"

@implementation MTIVertices

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count {
    if (self = [super init]) {
        _count = count;
        _buffer = calloc(count, sizeof(MTIVertex));
        memcpy(_buffer, vertices, count * sizeof(MTIVertex));
    }
    return self;
}

- (void)dealloc {
    if (_buffer) {
        free(_buffer);
    }
}

@end
