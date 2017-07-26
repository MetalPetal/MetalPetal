//
//  MTIVector+Private.h
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import <Foundation/Foundation.h>
#import "MTIVector.h"

@interface MTIVector()

- (MTIFloat *)bytes;

- (size_t)count;

- (NSUInteger)length;

+ (instancetype)vectorWithDoubleValues:(const double *)values count:(size_t)count;
- (instancetype)initWithDoubleValues:(const double *)values count:(size_t)count NS_DESIGNATED_INITIALIZER;

@end
