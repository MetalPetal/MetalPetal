//
//  MTIMPSHistogramFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/6/11.
//

#import <Foundation/Foundation.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MTIHistogramType) {
    MTIHistogramTypeLuminance = 1 << 0,
    MTIHistogramTypeRGB = 1 << 1
};

@interface MTIMPSHistogramFilter : NSObject <MTIFilter>

- (void)setOutputPixelFormat:(MTLPixelFormat)outputPixelFormat NS_UNAVAILABLE;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) float scaleFactor; //Unimplemented

@property (nonatomic) MTIHistogramType type; //Unimplemented

@end

@interface MTIHistogramDisplayFilter: NSObject <MTIUnaryFilter>

@property (nonatomic) CGSize outputSize;

@end

NS_ASSUME_NONNULL_END
