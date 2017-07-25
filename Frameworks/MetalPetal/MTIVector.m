//
//  MTIVector.m
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import "MTIVector.h"
#import "MTIVector+Private.h"

@implementation MTIVector

- (MTIFloat *)bytes {
    return _ptr;
}

- (size_t)count {
    return _count;
}

- (NSUInteger)length {
    return _count * sizeof(MTIFloat);
}

+ (instancetype)vectorWithValues:(const MTIFloat *)values count:(size_t)count {
    return [[self alloc] initWithValues: values count: count];
}

- (instancetype)initWithValues:(const MTIFloat *)values count:(size_t)count {
    if (self = [super init]) {
        _count = count;
        _ptr = malloc(sizeof(MTIFloat) * count);
        memcpy(_ptr, values, sizeof(MTIFloat) * count);
    }
    return self;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    __typeof(self) vector = [[[self class] allocWithZone:zone] initWithValues:self.bytes count:self.count];
    return vector;
}

- (instancetype)initWithCGPoint:(CGPoint)p {
    float values[2] = {(float)p.x, (float)p.y};
    return [self initWithValues: values count: 2];
}

- (instancetype)initWithCGRect:(CGRect)r {
    MTIFloat values[4] = {(float)r.origin.x, (float)r.origin.y, (float)r.size.width, (float)r.size.height};
    return [self initWithValues: values count: 4];
}

- (instancetype)initWithCGAffineTransform:(CGAffineTransform)t {
    MTIFloat values[6] = {(float)t.a, (float)t.b, (float)t.c, (float)t.d, (float)t.tx, (float)t.ty};
    return [self initWithValues: values count: 6];
}

- (void)dealloc {
    if (_ptr != NULL) {
        free(_ptr);
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSData *data = [coder decodeObjectOfClass:[NSData class] forKey:@"bytes"];
    NSInteger count = [coder decodeIntegerForKey: @"count"];
    return [self initWithValues:data.bytes count:count];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSData *data = [NSData dataWithBytes:_ptr length:self.length];
    [coder encodeObject:data forKey:@"bytes"];
    [coder encodeInteger:_count forKey:@"count"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
