//
//  MTIMPSHistogramFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/6/11.
//

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <CoreGraphics/CoreGraphics.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MTIHistogramType) {
    MTIHistogramTypeLuminance = 1 << 0,
    MTIHistogramTypeRGB = 1 << 1
};

__attribute__((objc_subclassing_restricted))
@interface MTIMPSHistogramFilter : NSObject <MTIFilter>

- (void)setOutputPixelFormat:(MTLPixelFormat)outputPixelFormat NS_UNAVAILABLE;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) float scaleFactor; //Unimplemented

@property (nonatomic) MTIHistogramType type; //Unimplemented

@end

__attribute__((objc_subclassing_restricted))
@interface MTIHistogramDisplayFilter: NSObject <MTIUnaryFilter>

@property (nonatomic) CGSize outputSize;

@end

NS_ASSUME_NONNULL_END
