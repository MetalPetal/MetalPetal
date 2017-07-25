//
//  MTIVector.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>

#define MTIFloat float

@interface MTIVector : NSObject <NSCopying, NSSecureCoding>
{
    size_t _count;
    
    MTIFloat *_ptr;
}

/* Create a new vector object. */
+ (instancetype)vectorWithValues:(const MTIFloat *)values count:(size_t)count;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValues:(const MTIFloat *)values count:(size_t)count NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCGPoint:(CGPoint)p NS_AVAILABLE(10_9, 5_0);
- (instancetype)initWithCGRect:(CGRect)r NS_AVAILABLE(10_9, 5_0);
- (instancetype)initWithCGAffineTransform:(CGAffineTransform)t NS_AVAILABLE(10_9, 5_0);

@end
