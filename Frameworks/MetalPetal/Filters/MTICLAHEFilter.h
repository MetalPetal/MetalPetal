//
//  MTICLAHEFilter.h
//  Pods
//
//  Created by YuAo on 13/10/2017.
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

struct MTICLAHESize {
    NSUInteger width, height;
};
typedef struct MTICLAHESize MTICLAHESize;

FOUNDATION_EXPORT MTICLAHESize MTICLAHESizeMake(NSUInteger width, NSUInteger height) NS_SWIFT_UNAVAILABLE("Use MTICLAHESize.init instead.");

@interface MTICLAHEFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float clipLimit;

@property (nonatomic) MTICLAHESize tileGridSize;

@end

NS_ASSUME_NONNULL_END
