//
//  MTIAlphaType.m
//  Pods
//
//  Created by Yu Ao on 23/10/2017.
//

#import "MTIAlphaType.h"
#import "MTIImage.h"

NSString * MTIAlphaTypeGetDescription(MTIAlphaType alphaType) {
    switch (alphaType) {
        case MTIAlphaTypePremultiplied:
            return @"Premultiplied";
        case MTIAlphaTypeNonPremultiplied:
            return @"NonPremultiplied";
        case MTIAlphaTypeAlphaIsOne:
            return @"AlphaIsOne";
        default:
            return @"UnknownAlphaType";
    }
}

@interface MTIAlphaTypeHandlingRule ()

@property (nonatomic,copy,readonly) MTIAlphaTypeHandlingOutputAlphaTypeRule outputAlphaTypeHandler;
@property (nonatomic,readonly) MTIAlphaType outputAlphaType;

@end

@implementation MTIAlphaTypeHandlingRule

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaTypeHandler:(MTIAlphaTypeHandlingOutputAlphaTypeRule)outputAlphaTypeHandler {
    if (self = [super init]) {
        _acceptableAlphaTypes = acceptableAlphaTypes;
        _outputAlphaTypeHandler = [outputAlphaTypeHandler copy];
    }
    return self;
}

- (instancetype)initWithAcceptableAlphaTypes:(NSArray<NSNumber *> *)acceptableAlphaTypes outputAlphaType:(MTIAlphaType)outputAlphaType {
    if (self = [super init]) {
        _acceptableAlphaTypes = acceptableAlphaTypes;
        _outputAlphaType = outputAlphaType;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)canAcceptAlphaType:(MTIAlphaType)alphaType {
    return [self.acceptableAlphaTypes containsObject:@(alphaType)];
}

- (MTIAlphaType)outputAlphaTypeForInputAlphaTypes:(NSArray<NSNumber *> *)inputAlphaTypes {
    if (_outputAlphaTypeHandler) {
        return _outputAlphaTypeHandler(inputAlphaTypes);
    } else {
        return _outputAlphaType;
    }
}

- (MTIAlphaType)outputAlphaTypeForInputImages:(NSArray<MTIImage *> *)inputImages {
    if (_outputAlphaTypeHandler) {
        NSMutableArray *alphaTypes = [NSMutableArray arrayWithCapacity:inputImages.count];
        for (MTIImage *image in inputImages) {
            [alphaTypes addObject:@(image.alphaType)];
        }
        NSParameterAssert([[NSSet setWithArray:alphaTypes] isSubsetOfSet:[NSSet setWithArray:_acceptableAlphaTypes]]);
        return [self outputAlphaTypeForInputAlphaTypes:alphaTypes];
    } else {
        return _outputAlphaType;
    }
}

+ (MTIAlphaTypeHandlingRule *)generalAlphaTypeHandlingRule {
    static MTIAlphaTypeHandlingRule * generalAlphaTypeHandlingRule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        generalAlphaTypeHandlingRule = [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypeNonPremultiplied),@(MTIAlphaTypeAlphaIsOne)] outputAlphaType:MTIAlphaTypeNonPremultiplied];
    });
    return generalAlphaTypeHandlingRule;
}

+ (MTIAlphaTypeHandlingRule *)passthroughAlphaTypeHandlingRule {
    static MTIAlphaTypeHandlingRule * passthroughAlphaTypeHandlingRule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        passthroughAlphaTypeHandlingRule = [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypeNonPremultiplied),@(MTIAlphaTypeAlphaIsOne),@(MTIAlphaTypePremultiplied)] outputAlphaTypeHandler:^MTIAlphaType(NSArray<NSNumber *> * _Nonnull inputAlphaTypes) {
            NSAssert(inputAlphaTypes.count == 1, @"");
            return [inputAlphaTypes.firstObject integerValue];
        }];
    });
    return passthroughAlphaTypeHandlingRule;
}

@end
