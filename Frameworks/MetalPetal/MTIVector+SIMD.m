//
//  MTIVector+SIMD.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/6/30.
//
//  Auto generated.

#import "MTIVector+SIMD.h"

@implementation MTIVector (SIMD)

+ (instancetype)vectorWithFloat2:(simd_float2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float2));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float2)float2Value {
    simd_float2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float2)) {
        memcpy(&value, self.bytes, sizeof(simd_float2));
    } else {
        NSAssert(NO, @"Cannot get a simd_float2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat3:(simd_float3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float3));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float3)float3Value {
    simd_float3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float3)) {
        memcpy(&value, self.bytes, sizeof(simd_float3));
    } else {
        NSAssert(NO, @"Cannot get a simd_float3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat4:(simd_float4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float4));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float4)float4Value {
    simd_float4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float4)) {
        memcpy(&value, self.bytes, sizeof(simd_float4));
    } else {
        NSAssert(NO, @"Cannot get a simd_float4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat8:(simd_float8)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float8));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float8)float8Value {
    simd_float8 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float8)) {
        memcpy(&value, self.bytes, sizeof(simd_float8));
    } else {
        NSAssert(NO, @"Cannot get a simd_float8 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat16:(simd_float16)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float16));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float16)float16Value {
    simd_float16 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float16)) {
        memcpy(&value, self.bytes, sizeof(simd_float16));
    } else {
        NSAssert(NO, @"Cannot get a simd_float16 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat2x2:(simd_float2x2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float2x2));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float2x2)float2x2Value {
    simd_float2x2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float2x2)) {
        memcpy(&value, self.bytes, sizeof(simd_float2x2));
    } else {
        NSAssert(NO, @"Cannot get a simd_float2x2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat2x3:(simd_float2x3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float2x3));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float2x3)float2x3Value {
    simd_float2x3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float2x3)) {
        memcpy(&value, self.bytes, sizeof(simd_float2x3));
    } else {
        NSAssert(NO, @"Cannot get a simd_float2x3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat2x4:(simd_float2x4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float2x4));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float2x4)float2x4Value {
    simd_float2x4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float2x4)) {
        memcpy(&value, self.bytes, sizeof(simd_float2x4));
    } else {
        NSAssert(NO, @"Cannot get a simd_float2x4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat3x2:(simd_float3x2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float3x2));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float3x2)float3x2Value {
    simd_float3x2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float3x2)) {
        memcpy(&value, self.bytes, sizeof(simd_float3x2));
    } else {
        NSAssert(NO, @"Cannot get a simd_float3x2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat3x3:(simd_float3x3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float3x3));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float3x3)float3x3Value {
    simd_float3x3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float3x3)) {
        memcpy(&value, self.bytes, sizeof(simd_float3x3));
    } else {
        NSAssert(NO, @"Cannot get a simd_float3x3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat3x4:(simd_float3x4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float3x4));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float3x4)float3x4Value {
    simd_float3x4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float3x4)) {
        memcpy(&value, self.bytes, sizeof(simd_float3x4));
    } else {
        NSAssert(NO, @"Cannot get a simd_float3x4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat4x2:(simd_float4x2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float4x2));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float4x2)float4x2Value {
    simd_float4x2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float4x2)) {
        memcpy(&value, self.bytes, sizeof(simd_float4x2));
    } else {
        NSAssert(NO, @"Cannot get a simd_float4x2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat4x3:(simd_float4x3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float4x3));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float4x3)float4x3Value {
    simd_float4x3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float4x3)) {
        memcpy(&value, self.bytes, sizeof(simd_float4x3));
    } else {
        NSAssert(NO, @"Cannot get a simd_float4x3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithFloat4x4:(simd_float4x4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float4x4));
    const float * valuePtr = (void *)&value;
    return [self vectorWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
}

- (simd_float4x4)float4x4Value {
    simd_float4x4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeFloat && self.byteLength == sizeof(simd_float4x4)) {
        memcpy(&value, self.bytes, sizeof(simd_float4x4));
    } else {
        NSAssert(NO, @"Cannot get a simd_float4x4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithInt2:(simd_int2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_int2));
    const int * valuePtr = (void *)&value;
    return [self vectorWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
}

- (simd_int2)int2Value {
    simd_int2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeInt && self.byteLength == sizeof(simd_int2)) {
        memcpy(&value, self.bytes, sizeof(simd_int2));
    } else {
        NSAssert(NO, @"Cannot get a simd_int2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithInt3:(simd_int3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_int3));
    const int * valuePtr = (void *)&value;
    return [self vectorWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
}

- (simd_int3)int3Value {
    simd_int3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeInt && self.byteLength == sizeof(simd_int3)) {
        memcpy(&value, self.bytes, sizeof(simd_int3));
    } else {
        NSAssert(NO, @"Cannot get a simd_int3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithInt4:(simd_int4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_int4));
    const int * valuePtr = (void *)&value;
    return [self vectorWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
}

- (simd_int4)int4Value {
    simd_int4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeInt && self.byteLength == sizeof(simd_int4)) {
        memcpy(&value, self.bytes, sizeof(simd_int4));
    } else {
        NSAssert(NO, @"Cannot get a simd_int4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithInt8:(simd_int8)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_int8));
    const int * valuePtr = (void *)&value;
    return [self vectorWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
}

- (simd_int8)int8Value {
    simd_int8 value = {0};
    if (self.scalarType == MTIVectorScalarTypeInt && self.byteLength == sizeof(simd_int8)) {
        memcpy(&value, self.bytes, sizeof(simd_int8));
    } else {
        NSAssert(NO, @"Cannot get a simd_int8 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithInt16:(simd_int16)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_int16));
    const int * valuePtr = (void *)&value;
    return [self vectorWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
}

- (simd_int16)int16Value {
    simd_int16 value = {0};
    if (self.scalarType == MTIVectorScalarTypeInt && self.byteLength == sizeof(simd_int16)) {
        memcpy(&value, self.bytes, sizeof(simd_int16));
    } else {
        NSAssert(NO, @"Cannot get a simd_int16 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUInt2:(simd_uint2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint2));
    const uint * valuePtr = (void *)&value;
    return [self vectorWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
}

- (simd_uint2)uint2Value {
    simd_uint2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUInt && self.byteLength == sizeof(simd_uint2)) {
        memcpy(&value, self.bytes, sizeof(simd_uint2));
    } else {
        NSAssert(NO, @"Cannot get a simd_uint2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUInt3:(simd_uint3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint3));
    const uint * valuePtr = (void *)&value;
    return [self vectorWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
}

- (simd_uint3)uint3Value {
    simd_uint3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUInt && self.byteLength == sizeof(simd_uint3)) {
        memcpy(&value, self.bytes, sizeof(simd_uint3));
    } else {
        NSAssert(NO, @"Cannot get a simd_uint3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUInt4:(simd_uint4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint4));
    const uint * valuePtr = (void *)&value;
    return [self vectorWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
}

- (simd_uint4)uint4Value {
    simd_uint4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUInt && self.byteLength == sizeof(simd_uint4)) {
        memcpy(&value, self.bytes, sizeof(simd_uint4));
    } else {
        NSAssert(NO, @"Cannot get a simd_uint4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUInt8:(simd_uint8)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint8));
    const uint * valuePtr = (void *)&value;
    return [self vectorWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
}

- (simd_uint8)uint8Value {
    simd_uint8 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUInt && self.byteLength == sizeof(simd_uint8)) {
        memcpy(&value, self.bytes, sizeof(simd_uint8));
    } else {
        NSAssert(NO, @"Cannot get a simd_uint8 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUInt16:(simd_uint16)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint16));
    const uint * valuePtr = (void *)&value;
    return [self vectorWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
}

- (simd_uint16)uint16Value {
    simd_uint16 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUInt && self.byteLength == sizeof(simd_uint16)) {
        memcpy(&value, self.bytes, sizeof(simd_uint16));
    } else {
        NSAssert(NO, @"Cannot get a simd_uint16 value from %@", self);
    }
    return value;
}


@end
