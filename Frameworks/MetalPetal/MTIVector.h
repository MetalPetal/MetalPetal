//
//  MTIVector.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>

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
- (instancetype)initWithCGAffineTransform:(CGAffineTransform)t;

@property (readonly) NSUInteger count;

@property (readonly) const float *bytes NS_RETURNS_INNER_POINTER;

@property (nonatomic,copy,readonly) NSData *data;

@property (readonly) CGPoint CGPointValue;

@property (readonly) CGSize CGSizeValue;

@property (readonly) CGRect CGRectValue;

@property (readonly) CGAffineTransform CGAffineTransformValue;

@end
