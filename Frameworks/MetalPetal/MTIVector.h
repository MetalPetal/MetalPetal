//
//  MTIVector.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTIVectorScalarType) {
    MTIVectorScalarTypeFloat,
    MTIVectorScalarTypeInt,
    MTIVectorScalarTypeUInt NS_SWIFT_NAME(uint)
} NS_SWIFT_NAME(MTIVector.ScalarType);

@interface MTIVector : NSObject <NSCopying, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithFloatValues:(const float *)values count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithIntValues:(const int *)values count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUIntValues:(const uint *)values count:(NSUInteger)count NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(uintValues:count:));

+ (instancetype)vectorWithFloatValues:(const float *)values count:(NSUInteger)count;
+ (instancetype)vectorWithIntValues:(const int *)values count:(NSUInteger)count;
+ (instancetype)vectorWithUIntValues:(const uint *)values count:(NSUInteger)count NS_SWIFT_NAME(init(uintValues:count:));

@property (readonly, nonatomic) MTIVectorScalarType scalarType;

@property (readonly, nonatomic) NSUInteger count;

+ (instancetype)vectorWithX:(float)X Y:(float)Y;
+ (instancetype)vectorWithCGPoint:(CGPoint)point NS_SWIFT_NAME(init(value:));
+ (instancetype)vectorWithCGSize:(CGSize)size NS_SWIFT_NAME(init(value:));
+ (instancetype)vectorWithCGRect:(CGRect)rect NS_SWIFT_NAME(init(value:));

@property (readonly) CGPoint CGPointValue;
@property (readonly) CGSize CGSizeValue;
@property (readonly) CGRect CGRectValue;

@end

@interface MTIVector (Contents)

@property (readonly) NSUInteger byteLength;

- (const void *)bytes NS_RETURNS_INNER_POINTER;

@end

NS_ASSUME_NONNULL_END
