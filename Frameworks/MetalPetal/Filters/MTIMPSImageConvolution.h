//
//  MTIMPSImageConvolution.h
//  Pods
//
//  Created by shuyj on 2017/8/14.
//
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

@interface MTIMPSImageConvolution : NSObject <MTIFilter>

@property (nonatomic, assign)   NSInteger       width;
@property (nonatomic, assign)   NSInteger       height;
@property (nonatomic, assign)   float* _Nonnull    matrixConvolution;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

- (instancetype _Nonnull )init NS_UNAVAILABLE;

- (instancetype _Nullable )initWithWidth:(NSInteger)width Height:(NSInteger)height Weights:(const float* _Nonnull) matrixPoint;

@end
