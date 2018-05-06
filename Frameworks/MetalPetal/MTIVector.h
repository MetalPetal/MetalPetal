//
//  MTIVector.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIVector : NSObject <NSCopying, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithValues:(const float *)values count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

+ (instancetype)vectorWithValues:(const float *)values count:(NSUInteger)count;

- (instancetype)initWithFloat2:(simd_float2)v;
- (instancetype)initWithFloat3:(simd_float3)v;
- (instancetype)initWithFloat4:(simd_float4)v;
- (instancetype)initWithFloat4x4:(simd_float4x4)v;

+ (instancetype)vectorWithX:(float)X Y:(float)Y;
+ (instancetype)vectorWithCGPoint:(CGPoint)point;
+ (instancetype)vectorWithCGSize:(CGSize)size;
+ (instancetype)vectorWithCGRect:(CGRect)rect;

+ (instancetype)vectorWithFloat2:(simd_float2)v;
+ (instancetype)vectorWithFloat3:(simd_float3)v;
+ (instancetype)vectorWithFloat4:(simd_float4)v;
+ (instancetype)vectorWithFloat4x4:(simd_float4x4)m;

@property (readonly) CGPoint CGPointValue;
@property (readonly) CGSize CGSizeValue;
@property (readonly) CGRect CGRectValue;
@property (readonly) simd_float2 float2Value;
@property (readonly) simd_float3 float3Value;
@property (readonly) simd_float4 float4Value;
@property (readonly) simd_float4x4 float4x4Value;

@property (readonly) NSUInteger count;

@property (nonatomic,copy,readonly) NSData *data;

@end

NS_ASSUME_NONNULL_END
