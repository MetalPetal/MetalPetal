//
//  MTIColor.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import <Foundation/Foundation.h>

struct MTIColor {
    float red;
    float green;
    float blue;
    float alpha;
};
typedef struct MTIColor MTIColor;

FOUNDATION_EXPORT MTIColor MTIColorMake(float red, float green, float blue, float alpha) NS_SWIFT_UNAVAILABLE("Use MTIColor.init instead.");
