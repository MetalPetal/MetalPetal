//
//  MTIVector.m
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import "MTIVector.h"
#import <AssertMacros.h>
@import Accelerate;
@import SceneKit;

__Check_Compile_Time(sizeof(simd_float4) == sizeof(simd_float3));

@implementation MTIVector

- (const float *)bytes {
    return self.data.bytes;
}

- (instancetype)initWithValues:(const float *)values count:(NSUInteger)count {
    if (self = [super init]) {
        NSParameterAssert(values);
        NSParameterAssert(count > 0);
        _count = count;
        _data = [NSData dataWithBytes:values length:count * sizeof(float)];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (instancetype)vectorWithValues:(const float *)values count:(NSUInteger)count {
    return [[self alloc] initWithValues:values count:count];
}

- (instancetype)initWithFloat2:(simd_float2)v {
    const float * values = (void *)&v;
    return [self initWithValues:values count:sizeof(v)/sizeof(float)];
}

- (instancetype)initWithFloat3:(simd_float3)v {
    simd_float4 float4 = simd_make_float4(v, 0);
    return [self initWithFloat4:float4];
}

- (instancetype)initWithFloat4:(simd_float4)v {
    const float * values = (void *)&v;
    return [self initWithValues:values count:sizeof(v)/sizeof(float)];
}

- (instancetype)initWithFloat4x4:(simd_float4x4)m {
    const float * values = (void *)&m;
    return [self initWithValues:values count:sizeof(m)/sizeof(float)];
}

+ (instancetype)vectorWithX:(float)X Y:(float)Y {
    float values[2] = {X, Y};
    return [[self alloc] initWithValues:values count:2];
}

+ (instancetype)vectorWithCGPoint:(CGPoint)p {
    float values[2] = {(float)p.x, (float)p.y};
    return [[self alloc] initWithValues:values count:2];
}

+ (instancetype)vectorWithCGSize:(CGSize)s {
    float values[2] = {(float)s.width, (float)s.height};
    return [[self alloc] initWithValues:values count:2];
}

+ (instancetype)vectorWithCGRect:(CGRect)r {
    float values[4] = {(float)r.origin.x, (float)r.origin.y, (float)r.size.width, (float)r.size.height};
    return [[self alloc] initWithValues:values count:4];
}

+ (instancetype)vectorWithFloat2:(simd_float2)v {
    return [[self alloc] initWithFloat2:v];
}

+ (instancetype)vectorWithFloat3:(simd_float3)v {
    return [[self alloc] initWithFloat3:v];
}

+ (instancetype)vectorWithFloat4:(simd_float4)v {
    return [[self alloc] initWithFloat4:v];
}

+ (instancetype)vectorWithFloat4x4:(simd_float4x4)m {
    return [[self alloc] initWithFloat4x4:m];
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

- (simd_float4x4)float4x4Value {
    if (self.count == sizeof(simd_float4x4)/sizeof(float)) {
        simd_float4x4 m;
        [self.data getBytes:&m length:sizeof(m)];
    }
    return matrix_identity_float4x4;
}

- (simd_float2)float2Value {
    if (self.count == sizeof(simd_float2)/sizeof(float)) {
        simd_float2 v;
        [self.data getBytes:&v length:sizeof(v)];
    }
    return (simd_float2){0,0};
}

- (simd_float4)float4Value {
    if (self.count == sizeof(simd_float4)/sizeof(float)) {
        simd_float4 v;
        [self.data getBytes:&v length:sizeof(v)];
    }
    return (simd_float4){0,0,0,0};
}

- (simd_float3)float3Value {
    return self.float4Value.xyz;
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
