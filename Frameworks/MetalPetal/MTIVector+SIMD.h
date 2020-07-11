//
//  MTIVector+SIMD.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/6/30.
//
//  Auto generated.

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIVector.h>
#else
#import "MTIVector.h"
#endif

NS_ASSUME_NONNULL_BEGIN

// WARNING: -[MTIVector isEqual:] may not work on MTIVector which contains a simd_type3 or simd_typeNx3 value.

@interface MTIVector (SIMD)

+ (instancetype)vectorWithFloat2:(simd_float2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float2 float2Value;

+ (instancetype)vectorWithFloat3:(simd_float3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float3 float3Value;

+ (instancetype)vectorWithFloat4:(simd_float4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float4 float4Value;

+ (instancetype)vectorWithFloat2x2:(simd_float2x2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float2x2 float2x2Value;

+ (instancetype)vectorWithFloat2x3:(simd_float2x3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float2x3 float2x3Value;

+ (instancetype)vectorWithFloat2x4:(simd_float2x4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float2x4 float2x4Value;

+ (instancetype)vectorWithFloat3x2:(simd_float3x2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float3x2 float3x2Value;

+ (instancetype)vectorWithFloat3x3:(simd_float3x3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float3x3 float3x3Value;

+ (instancetype)vectorWithFloat3x4:(simd_float3x4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float3x4 float3x4Value;

+ (instancetype)vectorWithFloat4x2:(simd_float4x2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float4x2 float4x2Value;

+ (instancetype)vectorWithFloat4x3:(simd_float4x3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float4x3 float4x3Value;

+ (instancetype)vectorWithFloat4x4:(simd_float4x4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_float4x4 float4x4Value;

+ (instancetype)vectorWithInt2:(simd_int2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_int2 int2Value;

+ (instancetype)vectorWithInt3:(simd_int3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_int3 int3Value;

+ (instancetype)vectorWithInt4:(simd_int4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_int4 int4Value;

+ (instancetype)vectorWithUInt2:(simd_uint2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uint2 uint2Value;

+ (instancetype)vectorWithUInt3:(simd_uint3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uint3 uint3Value;

+ (instancetype)vectorWithUInt4:(simd_uint4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uint4 uint4Value;

+ (instancetype)vectorWithShort2:(simd_short2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_short2 short2Value;

+ (instancetype)vectorWithShort3:(simd_short3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_short3 short3Value;

+ (instancetype)vectorWithShort4:(simd_short4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_short4 short4Value;

+ (instancetype)vectorWithUShort2:(simd_ushort2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_ushort2 ushort2Value;

+ (instancetype)vectorWithUShort3:(simd_ushort3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_ushort3 ushort3Value;

+ (instancetype)vectorWithUShort4:(simd_ushort4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_ushort4 ushort4Value;

+ (instancetype)vectorWithChar2:(simd_char2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_char2 char2Value;

+ (instancetype)vectorWithChar3:(simd_char3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_char3 char3Value;

+ (instancetype)vectorWithChar4:(simd_char4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_char4 char4Value;

+ (instancetype)vectorWithUChar2:(simd_uchar2)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uchar2 uchar2Value;

+ (instancetype)vectorWithUChar3:(simd_uchar3)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uchar3 uchar3Value;

+ (instancetype)vectorWithUChar4:(simd_uchar4)value NS_SWIFT_NAME(init(value:));

@property (nonatomic, readonly) simd_uchar4 uchar4Value;

@end

NS_ASSUME_NONNULL_END
