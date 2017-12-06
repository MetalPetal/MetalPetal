//
//  MTKTextureLoaderExtension.m
//  Pods
//
//  Created by Yu Ao on 06/12/2017.
//

#import "MTKTextureLoaderExtensions.h"
#import <objc/runtime.h>

MTKTextureLoaderOption const MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9 = @"MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9";

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}


@implementation MTIMTKTextureLoaderExtensions

- (BOOL)decodeCGImage_mti:(CGImageRef)image options:(NSDictionary *)options {
    return YES;
}

- (void)setImageOrientation:(NSUInteger)orientation {
    
}

static BOOL _automaticallyFlipsTextureOniOS9 = NO;

+ (void)setAutomaticallyFlipsTextureOniOS9:(BOOL)automaticallyFlipsTextureOniOS9 {
    _automaticallyFlipsTextureOniOS9 = automaticallyFlipsTextureOniOS9;
}

+ (BOOL)automaticallyFlipsTextureOniOS9 {
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_9_x_Max) {
        return _automaticallyFlipsTextureOniOS9;
    }
    return NO;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_9_x_Max) {
                Class MTKTextureLoaderDataClass = NSClassFromString([@"MTKTextureLoader" stringByAppendingString:@"ImageIO"]);
                SEL selector = NSSelectorFromString([@"decodeCGImage" stringByAppendingString:@":options:"]);
                SEL overrideSelector = @selector(decodeCGImage_mti:options:);
                class_addMethod(MTKTextureLoaderDataClass, overrideSelector, imp_implementationWithBlock(^(id _self, CGImageRef image, NSDictionary *options){
                    NSNumber *orientation = options[MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9];
                    if (orientation != nil) {
                        [_self setImageOrientation:[orientation unsignedIntegerValue]];
                    }
                    return [_self decodeCGImage_mti:image options:options];
                }), [MTKTextureLoaderDataClass instanceMethodSignatureForSelector:@selector(selector)].methodReturnType);
                class_swizzleSelector(MTKTextureLoaderDataClass, selector, overrideSelector);
            }
        }
    });
}

@end
