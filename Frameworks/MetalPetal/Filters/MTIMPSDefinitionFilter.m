//
//  MTIMPSDefinitionFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/21.
//

#import "MTIMPSDefinitionFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"

@interface MTIMPSDefinitionFilter ()

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *blurFilter;

@end

@implementation MTIMPSDefinitionFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    return [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                  fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"clarity"]];
}

- (instancetype)init {
    if (self = [super init]) {
        _blurFilter = [[MTIMPSGaussianBlurFilter alloc] init];
    }
    return self;
}

- (void)setInputImage:(MTIImage *)inputImage {
    _inputImage = inputImage;
    _blurFilter.inputImage = inputImage;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    if (self.intensity <= 0) {
        return self.inputImage;
    }
    
    self.blurFilter.radius = self.inputImage.size.width / 1024.0 * 32.0;
    MTIImage *blurredImage = self.blurFilter.outputImage;
    
    return [MTIMPSDefinitionFilter.kernel applyToInputImages:@[self.inputImage, blurredImage]
                                                  parameters:@{@"intensity": @(self.intensity)}
                                     outputTextureDimensions:self.inputImage.dimensions
                                           outputPixelFormat:self.outputPixelFormat];
}

@end
