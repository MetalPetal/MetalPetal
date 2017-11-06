//
//  MTIMPSImageConvolution.h
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIMPSConvolutionFilter : NSObject <MTIUnaryFilter>

/*! @property    bias
 *  @discussion  The bias is a value to be added to convolved pixel before it is converted back to the storage format.
 *               It can be used to convert negative values into a representable range for a unsigned MTLPixelFormat.
 *               For example, many edge detection filters produce results in the range [-k,k]. By scaling the filter
 *               weights by 0.5/k and adding 0.5, the results will be in range [0,1] suitable for use with unorm formats.
 *               It can be used in combination with renormalization of the filter weights to do video ranging as part
 *               of the convolution effect. It can also just be used to increase the brightness of the image.
 *
 *               Default value is 0.0f.
 */
@property (nonatomic) float bias;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float *)kernelWeights NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
