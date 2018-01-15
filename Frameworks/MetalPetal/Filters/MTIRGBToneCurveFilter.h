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

@property (nonatomic, copy) NSArray<MTIVector *> *redControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *greenControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *blueControlPoints;
@property (nonatomic, copy) NSArray<MTIVector *> *RGBCompositeControlPoints;

@property (nonatomic) float intensity; //default 1.0

@property (nonatomic, strong, readonly) MTIImage *toneCurveColorLookupImage;

@end

NS_ASSUME_NONNULL_END
