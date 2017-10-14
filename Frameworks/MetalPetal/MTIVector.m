//
//  MTIVector.m
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import "MTIVector.h"
@import Accelerate;
@import SceneKit;

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

- (instancetype)initWithFloat4x4:(simd_float4x4)m {
    SCNMatrix4 t = SCNMatrix4FromMat4(m);
    float values[16] = {
        (float)t.m11, (float)t.m12, (float)t.m13, (float)t.m14,
        (float)t.m21, (float)t.m22, (float)t.m23, (float)t.m24,
        (float)t.m31, (float)t.m32, (float)t.m33, (float)t.m34,
        (float)t.m41, (float)t.m42, (float)t.m43, (float)t.m44
    };
    return [self initWithValues:values count:16];
}

- (instancetype)initWithFloat2:(simd_float2)v {
    float values[2] = {v[0],v[1]};
    return [self initWithValues:values count:2];
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
    if (self.count == 2) {
        const float * bytes = self.bytes;
        return CGPointMake(bytes[0], bytes[1]);
    }
    return CGPointZero;
}

- (CGSize)CGSizeValue {
    if (self.count == 2) {
        const float * bytes = self.bytes;
        return CGSizeMake(bytes[0], bytes[1]);
    }
    return CGSizeZero;
}

- (CGRect)CGRectValue {
    if (self.count == 4) {
        const float * bytes = self.bytes;
        return CGRectMake(bytes[0], bytes[1], bytes[2], bytes[3]);
    }
    return CGRectZero;
}

- (CGAffineTransform)CGAffineTransformValue {
    if (self.count == 6) {
        const float * bytes = self.bytes;
        return CGAffineTransformMake(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]);
    }
    return CGAffineTransformIdentity;
}

- (simd_float4x4)float4x4Value {
    if (self.count == 16) {
        const float * bytes = self.bytes;
        SCNMatrix4 m = (SCNMatrix4){
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        };
        return SCNMatrix4ToMat4(m);
    }
    return matrix_identity_float4x4;
}

- (simd_float2)float2Value {
    if (self.count == 2) {
        const float * bytes = self.bytes;
        return (simd_float2){bytes[0], bytes[1]};
    }
    return (simd_float2){0,0};
}

- (CATransform3D)CATransform3DValue {
    if (self.count == 16) {
        const float * bytes = self.bytes;
        CATransform3D m = (CATransform3D){
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        };
        return m;
    }
    return CATransform3DIdentity;
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
