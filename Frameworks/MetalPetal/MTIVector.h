//
//  MTIVector.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>

typedef float MTIFloat;

@interface MTIVector : NSObject <NSCopying, NSSecureCoding>
{
    size_t _count;
    
    MTIFloat *_ptr;
}

/* Create a new vector object. */
+ (instancetype)vectorWithValues:(const MTIFloat *)values count:(size_t)count;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValues:(const MTIFloat *)values count:(size_t)count NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCGPoint:(CGPoint)p;
- (instancetype)initWithCGSize:(CGSize)s;
- (instancetype)initWithCGRect:(CGRect)r;
- (instancetype)initWithCGAffineTransform:(CGAffineTransform)t;

@property (readonly) NSData *data;
@property (readonly) CGPoint CGPointValue;
@property (readonly) CGSize CGSizeValue;
@property (readonly) CGRect CGRectValue;
@property (readonly) CGAffineTransform CGAffineTransformValue;

@end
