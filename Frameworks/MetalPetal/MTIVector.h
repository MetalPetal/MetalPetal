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

/* Create a new vector object. */
+ (instancetype)vectorWithValues:(const float *)values count:(NSUInteger)count;
+ (instancetype)vectorWithDoubleValues:(const double *)values count:(NSUInteger)count;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithValues:(const float *)values count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCGPoint:(CGPoint)p;
- (instancetype)initWithCGSize:(CGSize)s;
- (instancetype)initWithCGRect:(CGRect)r;
- (instancetype)initWithFloat4x4:(simd_float4x4)m;
- (instancetype)initWithFloat2:(simd_float2)v;
- (instancetype)initWithFloat4:(simd_float4)v;
- (instancetype)initWithFloat3:(simd_float3)v;

+ (instancetype)vectorWithX:(float)X Y:(float)Y;

@property (readonly) NSUInteger count;

@property (nonatomic,copy,readonly) NSData *data;

@property (readonly) CGPoint CGPointValue;

@property (readonly) CGSize CGSizeValue;

@property (readonly) CGRect CGRectValue;

@property (readonly) simd_float4x4 float4x4Value;

@property (readonly) simd_float2 float2Value;

@property (readonly) simd_float4 float4Value;

@property (readonly) simd_float3 float3Value;

@end

NS_ASSUME_NONNULL_END
