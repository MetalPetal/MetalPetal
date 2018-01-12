//
//  MTIRGBToneCurveFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 12/01/2018.
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIRGBToneCurveFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, copy) NSArray<NSValue *> *inputRedControlPoints;
@property (nonatomic, copy) NSArray<NSValue *> *inputGreenControlPoints;
@property (nonatomic, copy) NSArray<NSValue *> *inputBlueControlPoints;
@property (nonatomic, copy) NSArray<NSValue *> *inputRGBCompositeControlPoints;

@property (nonatomic) float intensity; //default 1.0

@end

NS_ASSUME_NONNULL_END
