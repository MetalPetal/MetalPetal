//
//  MTIPixelFormat.m
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//

#import "MTIPixelFormat.h"

MTIPixelFormat MTIPixelFormatMake(MTLPixelFormat value) {
    return (MTIPixelFormat){.type = MTIPixelFormatTypeConcreteValue, .value = value };
}

MTIPixelFormat MTIPixelFormatMakeWithUnspecifiedValue(void) {
    return (MTIPixelFormat){.type = MTIPixelFormatTypeUnspecifiedValue, .value = MTLPixelFormatInvalid };
}

BOOL MTIPixelFormatValueIsSpecified(MTIPixelFormat format) {
    return format.type != MTIPixelFormatTypeUnspecifiedValue;
}

BOOL MTIPixelFormatEqualToPixelFormat(MTIPixelFormat lhs, MTIPixelFormat rhs) {
    return lhs.type == rhs.type && lhs.value == rhs.value;
}

@implementation NSValue (MTIPixelFormat)

+ (instancetype)valueWithMTIPixelFormat:(MTIPixelFormat)pixelFormat {
    return [NSValue value:&pixelFormat withObjCType:@encode(MTIPixelFormat)];
}

- (MTIPixelFormat)mtiPixelFormatValue {
    MTIPixelFormat format = (MTIPixelFormat){.type = MTIPixelFormatTypeUnspecifiedValue, .value = MTLPixelFormatInvalid };
    if (strcmp(self.objCType, @encode(MTIPixelFormat)) == 0) {
        if (@available(iOS 11.0, *)) {
            [self getValue:&format size:sizeof(MTIPixelFormat)];
        } else {
            [self getValue:&format];
        }
    }
    return format;
}

@end
