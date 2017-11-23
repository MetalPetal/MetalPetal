//
//  MTIAlphaType.h
//  Pods
//
//  Created by Yu Ao on 23/10/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTIAlphaType) {
    MTIAlphaTypeUnknown = 0,
    MTIAlphaTypeNonPremultiplied = 1,
    MTIAlphaTypePremultiplied = 2,
    MTIAlphaTypeAlphaIsOne = 3
};

FOUNDATION_EXPORT NSString * MTIAlphaTypeGetDescription(MTIAlphaType alphaType);

@class MTIImage;

typedef MTIAlphaType (^MTIAlphaTypeHandlingOutputAlphaTypeRule)(NSArray<NSNumber *> *inputAlphaTypes);

@interface MTIAlphaTypeHandlingRule: NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *acceptableAlphaTypes NS_REFINED_FOR_SWIFT;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (BOOL)canAcceptAlphaType:(MTIAlphaType)alphaType;

- (MTIAlphaType)outputAlphaTypeForInputAlphaTypes:(NSArray<NSNumber *> *)inputAlphaTypes NS_REFINED_FOR_SWIFT;

- (MTIAlphaType)outputAlphaTypeForInputImages:(NSArray<MTIImage *> *)inputImages;

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaTypeHandler:(MTIAlphaTypeHandlingOutputAlphaTypeRule)outputAlphaTypeHandler NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaType:(MTIAlphaType)outputAlphaType NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

@property (nonatomic, copy, class, readonly) MTIAlphaTypeHandlingRule *generalAlphaTypeHandlingRule; //accepts MTIAlphaTypeNonPremultiplied, MTIAlphaTypeAlphaIsOne; outputs MTIAlphaTypeNonPremultiplied

@property (nonatomic, copy, class, readonly) MTIAlphaTypeHandlingRule *passthroughAlphaTypeHandlingRule; //accepts all; output is same as input.


@end

NS_ASSUME_NONNULL_END
