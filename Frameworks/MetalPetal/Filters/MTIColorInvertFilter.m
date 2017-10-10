//
//  MTIColorInvertFilter.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIColorInvertFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFilterUtilities.h"

@implementation MTIColorInvertFilter

+ (NSString *)fragmentFunctionName {
    return @"colorInvert";
}

@end
