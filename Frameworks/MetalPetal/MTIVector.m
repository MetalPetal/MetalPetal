//
//  MTIVector.m
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import "MTIVector.h"
@import Accelerate;

@implementation MTIVector

- (const float *)bytes {
    return self.data.bytes;
}

+ (instancetype)vectorWithValues:(const float *)values count:(NSUInteger)count {
    return [[self alloc] initWithValues:values count:count];
}

+ (instancetype)vectorWithDoubleValues:(const double *)values count:(NSUInteger)count {
    float result[count];
    vDSP_vdpsp(values, 1, result, 1, count);
    return [[self alloc] initWithValues:result count:count];
}

- (instancetype)initWithValues:(const float *)values count:(NSUInteger)count {
    if (self = [super init]) {
        _count = count;
        _data = [NSData dataWithBytes:values length:count * sizeof(float)];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithCGPoint:(CGPoint)p {
    float values[2] = {(float)p.x, (float)p.y};
    return [self initWithValues:values count:2];
}

- (instancetype)initWithCGSize:(CGSize)s {
    float values[2] = {(float)s.width, (float)s.height};
    return [self initWithValues:values count:2];
}

- (instancetype)initWithCGRect:(CGRect)r {
    float values[4] = {(float)r.origin.x, (float)r.origin.y, (float)r.size.width, (float)r.size.height};
    return [self initWithValues:values count:4];
}

- (instancetype)initWithCGAffineTransform:(CGAffineTransform)t {
    float values[6] = {(float)t.a, (float)t.b, (float)t.c, (float)t.d, (float)t.tx, (float)t.ty};
    return [self initWithValues:values count:6];
}

- (instancetype)initWithCATransform3D:(CATransform3D)t {
    float values[16] = {
        (float)t.m11, (float)t.m12, (float)t.m13, (float)t.m14,
        (float)t.m21, (float)t.m22, (float)t.m23, (float)t.m24,
        (float)t.m31, (float)t.m32, (float)t.m33, (float)t.m34,
        (float)t.m41, (float)t.m42, (float)t.m43, (float)t.m44
    };
    return [self initWithValues:values count:16];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSData *data = [coder decodeObjectOfClass:[NSData class] forKey:@"data"];
    if (!data) {
        return nil;
    }
    return [self initWithValues:data.bytes count:data.length/sizeof(float)];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_data forKey:@"data"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
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
    if (self.count > 5) {
        return CGAffineTransformMake(self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3], self.bytes[4], self.bytes[5]);
    }
    return CGAffineTransformIdentity;
}

- (NSUInteger)hash {
    return _data.hash;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIVector class]]) {
        MTIVector *other = object;
        if (self.count != other.count) {
            return NO;
        }
        return [_data isEqual:other -> _data];
    } else {
        return NO;
    }
}

@end
