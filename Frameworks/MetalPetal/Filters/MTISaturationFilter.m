//
//  MTISaturationFilter.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTISaturationFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFilterUtilities.h"

@implementation MTISaturationFilter

+ (NSString *)fragmentFunctionName {
    return @"saturationAdjust";
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"saturation", nil];
}

@end
