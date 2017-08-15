//
//  MTIMPSImageConvolution.h
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

@interface ConvolutionInputSets : NSObject<NSCopying>
@property (nonatomic, assign)    long       width;
@property (nonatomic, assign)    long       height;
@property (nonatomic, assign)    float* _Nullable matrixPoint;

- (instancetype _Nonnull )initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float* _Nonnull) matrixPoint;
@end

@interface MTIMPSImageConvolution : NSObject <MTIFilter>

@property (nonatomic, strong)   ConvolutionInputSets* _Nonnull inputSets;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

- (instancetype _Nonnull )init NS_UNAVAILABLE;

- (instancetype _Nullable )initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float* _Nonnull) matrixPoint;

@end
