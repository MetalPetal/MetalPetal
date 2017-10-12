//
//  MTIPixelFormat.h
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//


#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTIPixelFormatType) {
    MTIPixelFormatTypeUnspecifiedValue = 0,
    MTIPixelFormatTypeConcreteValue = 1
};

struct MTIPixelFormat {
    MTIPixelFormatType type;
    MTLPixelFormat value;
};
typedef struct MTIPixelFormat MTIPixelFormat;

FOUNDATION_EXPORT MTIPixelFormat MTIPixelFormatMake(MTLPixelFormat value) NS_SWIFT_NAME(MTIPixelFormat.init(value:));
FOUNDATION_EXPORT MTIPixelFormat MTIPixelFormatMakeWithUnspecifiedValue(void) NS_SWIFT_NAME(MTIPixelFormat.init());

FOUNDATION_EXPORT BOOL MTIPixelFormatValueIsSpecified(MTIPixelFormat format) NS_SWIFT_NAME(getter:MTIPixelFormat.isValueSpecified(self:));

FOUNDATION_EXPORT BOOL MTIPixelFormatEqualToPixelFormat(MTIPixelFormat lhs, MTIPixelFormat rhs) NS_SWIFT_NAME(MTIPixelFormat.isEqual(self:to:));

@interface NSValue (MTIPixelFormat)

+ (instancetype)valueWithMTIPixelFormat:(MTIPixelFormat)pixelFormat;

@property (nonatomic,readonly) MTIPixelFormat mtiPixelFormatValue;

@end


NS_ASSUME_NONNULL_END

