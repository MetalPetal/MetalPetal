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

+ (instancetype)vectorWithDoubleValues:(const double *)values count:(size_t)count {
    return [[self alloc] initWithDoubleValues:values count:count];
}

- (instancetype)initWithDoubleValues:(const double *)values count:(size_t)count {
    if (self = [super init]) {
        _count = count;
        _ptr = malloc(sizeof(MTIFloat) * count);
        for (size_t i = 0; i<count; i++) {
            _ptr[i] = (MTIFloat)values[i];
        }
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

- (instancetype)initWithCGSize:(CGSize)s {
    float values[2] = {(float)s.width, (float)s.height};
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
    return [self initWithValues:data.bytes count:(size_t)count];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSData *data = [NSData dataWithBytes:_ptr length:self.length];
    [coder encodeObject:data forKey:@"bytes"];
    [coder encodeInteger:(NSInteger)_count forKey:@"count"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSData *)data {
    return [NSData dataWithBytes:self.bytes length:self.length];
}

- (CGPoint)CGPointValue {
    if (self.count > 1) {
        return CGPointMake(self.bytes[0], self.bytes[1]);
    }
    return CGPointZero;
}

- (CGSize)CGSizeValue {
    if (self.count > 1) {
        return CGSizeMake(self.bytes[0], self.bytes[1]);
    }
    return CGSizeZero;
}

- (CGRect)CGRectValue {
    if (self.count > 3) {
        return CGRectMake(self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3]);
    }
    return CGRectZero;
}

- (CGAffineTransform)CGAffineTransformValue {
    if (self.count > 1) {
        return CGAffineTransformMake(self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3], self.bytes[4], self.bytes[5]);
    }
    return CGAffineTransformIdentity;
}

@end
