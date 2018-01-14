//
//  MTIRGBToneCurveFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 12/01/2018.
//

#import "MTIFilter.h"
#import "MTIVector.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIRGBToneCurveFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, copy) NSArray<MTIVector *> *inputRedControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *inputGreenControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *inputBlueControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *inputRGBCompositeControlPoints;

@property (nonatomic) float intensity; //default 1.0

@end

NS_ASSUME_NONNULL_END
