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

@interface MTIMPSImageConvolution : NSObject <MTIFilter>

@property (nonatomic, strong, readonly)   MTIConvolutionInputSets* _Nonnull inputSets;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithKernelWidth:(NSUInteger)kernelWidth kernelHeight:(NSUInteger)kernelHeight weights:(const float* __nonnull)kernelWeights NS_DESIGNATED_INITIALIZER;

@end
