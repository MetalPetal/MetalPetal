//
//  MTIMPSImageConvolution.h
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

@class MTIConvolutionInputSets;

/*!
 *  @class      MPSImageConvolution
 *  @discussion The MPSImageConvolution convolves an image with given filter of odd width and height.
 *              The center of the kernel aligns with the MPSImageConvolution.offset. That is, the position
 *              of the top left corner of the area covered by the kernel is given by
 *              MPSImageConvolution.offset - {kernel_width>>1, kernel_height>>1, 0}
 *
 *              Optimized cases include 3x3,5x5,7x7,9x9,11x11, 1xN and Nx1. If a convolution kernel
 *              does not fall into one of these cases but is a rank-1 matrix (a.k.a. separable)
 *              then it will fall on an optimzied separable path. Other convolutions will execute with
 *              full MxN complexity.
 *
 *              If there are multiple channels in the source image, each channel is processed independently.
 *
 */
@interface MTIMPSImageConvolution : NSObject <MTIFilter>

@property (nonatomic, strong, readonly)   MTIConvolutionInputSets* _Nonnull inputSets;

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
@property (readwrite, nonatomic) float bias;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float* __nonnull)kernelWeights NS_DESIGNATED_INITIALIZER;

@end
