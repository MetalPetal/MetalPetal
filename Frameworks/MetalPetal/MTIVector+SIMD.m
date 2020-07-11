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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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

+ (instancetype)vectorWithFloat2x2:(simd_float2x2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_float2x2));
    const float * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithFloatValues:valuePtr count:sizeof(value)/sizeof(float)];
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
    return [[MTIVector alloc] initWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
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
    return [[MTIVector alloc] initWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
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
    return [[MTIVector alloc] initWithIntValues:valuePtr count:sizeof(value)/sizeof(int)];
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

+ (instancetype)vectorWithUInt2:(simd_uint2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uint2));
    const uint * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
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
    return [[MTIVector alloc] initWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
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
    return [[MTIVector alloc] initWithUIntValues:valuePtr count:sizeof(value)/sizeof(uint)];
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

+ (instancetype)vectorWithShort2:(simd_short2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_short2));
    const short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithShortValues:valuePtr count:sizeof(value)/sizeof(short)];
}

- (simd_short2)short2Value {
    simd_short2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeShort && self.byteLength == sizeof(simd_short2)) {
        memcpy(&value, self.bytes, sizeof(simd_short2));
    } else {
        NSAssert(NO, @"Cannot get a simd_short2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithShort3:(simd_short3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_short3));
    const short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithShortValues:valuePtr count:sizeof(value)/sizeof(short)];
}

- (simd_short3)short3Value {
    simd_short3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeShort && self.byteLength == sizeof(simd_short3)) {
        memcpy(&value, self.bytes, sizeof(simd_short3));
    } else {
        NSAssert(NO, @"Cannot get a simd_short3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithShort4:(simd_short4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_short4));
    const short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithShortValues:valuePtr count:sizeof(value)/sizeof(short)];
}

- (simd_short4)short4Value {
    simd_short4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeShort && self.byteLength == sizeof(simd_short4)) {
        memcpy(&value, self.bytes, sizeof(simd_short4));
    } else {
        NSAssert(NO, @"Cannot get a simd_short4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUShort2:(simd_ushort2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_ushort2));
    const unsigned short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUShortValues:valuePtr count:sizeof(value)/sizeof(unsigned short)];
}

- (simd_ushort2)ushort2Value {
    simd_ushort2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUShort && self.byteLength == sizeof(simd_ushort2)) {
        memcpy(&value, self.bytes, sizeof(simd_ushort2));
    } else {
        NSAssert(NO, @"Cannot get a simd_ushort2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUShort3:(simd_ushort3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_ushort3));
    const unsigned short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUShortValues:valuePtr count:sizeof(value)/sizeof(unsigned short)];
}

- (simd_ushort3)ushort3Value {
    simd_ushort3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUShort && self.byteLength == sizeof(simd_ushort3)) {
        memcpy(&value, self.bytes, sizeof(simd_ushort3));
    } else {
        NSAssert(NO, @"Cannot get a simd_ushort3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUShort4:(simd_ushort4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_ushort4));
    const unsigned short * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUShortValues:valuePtr count:sizeof(value)/sizeof(unsigned short)];
}

- (simd_ushort4)ushort4Value {
    simd_ushort4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUShort && self.byteLength == sizeof(simd_ushort4)) {
        memcpy(&value, self.bytes, sizeof(simd_ushort4));
    } else {
        NSAssert(NO, @"Cannot get a simd_ushort4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithChar2:(simd_char2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_char2));
    const char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithCharValues:valuePtr count:sizeof(value)/sizeof(char)];
}

- (simd_char2)char2Value {
    simd_char2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeChar && self.byteLength == sizeof(simd_char2)) {
        memcpy(&value, self.bytes, sizeof(simd_char2));
    } else {
        NSAssert(NO, @"Cannot get a simd_char2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithChar3:(simd_char3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_char3));
    const char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithCharValues:valuePtr count:sizeof(value)/sizeof(char)];
}

- (simd_char3)char3Value {
    simd_char3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeChar && self.byteLength == sizeof(simd_char3)) {
        memcpy(&value, self.bytes, sizeof(simd_char3));
    } else {
        NSAssert(NO, @"Cannot get a simd_char3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithChar4:(simd_char4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_char4));
    const char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithCharValues:valuePtr count:sizeof(value)/sizeof(char)];
}

- (simd_char4)char4Value {
    simd_char4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeChar && self.byteLength == sizeof(simd_char4)) {
        memcpy(&value, self.bytes, sizeof(simd_char4));
    } else {
        NSAssert(NO, @"Cannot get a simd_char4 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUChar2:(simd_uchar2)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uchar2));
    const unsigned char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUCharValues:valuePtr count:sizeof(value)/sizeof(unsigned char)];
}

- (simd_uchar2)uchar2Value {
    simd_uchar2 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUChar && self.byteLength == sizeof(simd_uchar2)) {
        memcpy(&value, self.bytes, sizeof(simd_uchar2));
    } else {
        NSAssert(NO, @"Cannot get a simd_uchar2 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUChar3:(simd_uchar3)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uchar3));
    const unsigned char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUCharValues:valuePtr count:sizeof(value)/sizeof(unsigned char)];
}

- (simd_uchar3)uchar3Value {
    simd_uchar3 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUChar && self.byteLength == sizeof(simd_uchar3)) {
        memcpy(&value, self.bytes, sizeof(simd_uchar3));
    } else {
        NSAssert(NO, @"Cannot get a simd_uchar3 value from %@", self);
    }
    return value;
}

+ (instancetype)vectorWithUChar4:(simd_uchar4)value {
    NSParameterAssert(sizeof(value) == sizeof(simd_uchar4));
    const unsigned char * valuePtr = (void *)&value;
    return [[MTIVector alloc] initWithUCharValues:valuePtr count:sizeof(value)/sizeof(unsigned char)];
}

- (simd_uchar4)uchar4Value {
    simd_uchar4 value = {0};
    if (self.scalarType == MTIVectorScalarTypeUChar && self.byteLength == sizeof(simd_uchar4)) {
        memcpy(&value, self.bytes, sizeof(simd_uchar4));
    } else {
        NSAssert(NO, @"Cannot get a simd_uchar4 value from %@", self);
    }
    return value;
}


@end
