//
//  MTIAlphaType.h
//  Pods
//
//  Created by Yu Ao on 23/10/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Describe different ways to represent the opacity of a color value. See also: https://microsoft.github.io/Win2D/html/PremultipliedAlpha.htm
typedef NS_CLOSED_ENUM(NSInteger, MTIAlphaType) {
    /// MTIAlphaTypeUnknown The alpha type is unknown.
    MTIAlphaTypeUnknown = 0,
    
    /// RGB values specify the color of the thing being drawn. The alpha value specifies how solid it is.
    MTIAlphaTypeNonPremultiplied = 1,
    
    /// RGB specifies how much color the thing being drawn contributes to the output. The alpha value specifies how much it obscures whatever is behind it.
    MTIAlphaTypePremultiplied = 2,
    
    /// There is no alpha channel or the alpha value is one.
    MTIAlphaTypeAlphaIsOne = 3
};

FOUNDATION_EXPORT NSString * MTIAlphaTypeGetDescription(MTIAlphaType alphaType);

@class MTIImage;

typedef MTIAlphaType (^MTIAlphaTypeHandlingOutputAlphaTypeRule)(NSArray<NSNumber *> *inputAlphaTypes);

/// Describes how a image processing unit handles alpha type.
@interface MTIAlphaTypeHandlingRule: NSObject <NSCopying>

/// Acceptable alpha types.
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *acceptableAlphaTypes NS_REFINED_FOR_SWIFT;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (BOOL)canAcceptAlphaType:(MTIAlphaType)alphaType;

- (MTIAlphaType)outputAlphaTypeForInputAlphaTypes:(NSArray<NSNumber *> *)inputAlphaTypes NS_REFINED_FOR_SWIFT;

- (MTIAlphaType)outputAlphaTypeForInputImages:(NSArray<MTIImage *> *)inputImages;

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaTypeHandler:(MTIAlphaTypeHandlingOutputAlphaTypeRule)outputAlphaTypeHandler NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaType:(MTIAlphaType)outputAlphaType NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

/// Accepts MTIAlphaTypeNonPremultiplied, MTIAlphaTypeAlphaIsOne. Outputs MTIAlphaTypeNonPremultiplied.
@property (nonatomic, copy, class, readonly) MTIAlphaTypeHandlingRule *generalAlphaTypeHandlingRule;

/// Accepts all alpha types. The output alpha type is the same as input alpha type.
@property (nonatomic, copy, class, readonly) MTIAlphaTypeHandlingRule *passthroughAlphaTypeHandlingRule;


@end

NS_ASSUME_NONNULL_END
