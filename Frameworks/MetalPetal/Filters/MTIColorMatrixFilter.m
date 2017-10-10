//
//  MTIColorMatrixFilter.m
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIColorMatrixFilter.h"
#import "MTIFilterUtilities.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIVector.h"

@interface MTIColorMatrixFilter ()

@property (nonatomic,copy) MTIVector *colorMatrixValue;

@end

@implementation MTIColorMatrixFilter

+ (NSString *)fragmentFunctionName {
    return @"colorMatrixProjection";
}

- (instancetype)init {
    if (self = [super init]) {
        self.colorMatrix = matrix_identity_float4x4;
    }
    return self;
}

- (void)setColorMatrix:(simd_float4x4)colorMatrix {
    _colorMatrixValue = [[MTIVector alloc] initWithFloat4x4:colorMatrix];
    _colorMatrix = colorMatrix;
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"colorMatrixValue", nil];
}

@end
