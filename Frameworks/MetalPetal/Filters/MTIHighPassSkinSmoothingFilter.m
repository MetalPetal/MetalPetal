//
//  MTIHighPassSkinSmoothingFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 15/01/2018.
//

#import "MTIHighPassSkinSmoothingFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIRGBToneCurveFilter.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface MTIHighPassSkinSmoothingFilter ()

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *blurFilter;
@property (nonatomic, strong) MTIRGBToneCurveFilter *toneCurveFilter;

@end

@implementation MTIHighPassSkinSmoothingFilter
@synthesize outputImage = _outputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (NSArray<MTIVector *> *)defaultToneCurveControlPoints {
    return @[[MTIVector vectorWithX:0 Y:0],
             [MTIVector vectorWithX:120/255.0 Y:146/255.0],
             [MTIVector vectorWithX:1.0 Y:1.0]];
}

+ (MTIRenderPipelineKernel *)GBChannelOverlayBlendKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"highPassSkinSmoothingGBChannelOverlay"]];
    });
    return kernel;
}


+ (MTIRenderPipelineKernel *)maskProcessAndCompositeKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"highPassSkinSmoothingMaskProcessAndComposite"]];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _toneCurveControlPoints = [MTIHighPassSkinSmoothingFilter defaultToneCurveControlPoints];
        _amount = 0.65;
        _radius = 8.0;
        _blurFilter = [[MTIMPSGaussianBlurFilter alloc] init];
        _toneCurveFilter = [[MTIRGBToneCurveFilter alloc] init];
        _toneCurveFilter.RGBCompositeControlPoints = _toneCurveControlPoints;
    }
    return self;
}

- (void)setToneCurveControlPoints:(NSArray<MTIVector *> *)toneCurveControlPoints {
    if (toneCurveControlPoints == nil || toneCurveControlPoints.count < 2) {
        _toneCurveControlPoints = [MTIHighPassSkinSmoothingFilter defaultToneCurveControlPoints];
    } else {
        _toneCurveControlPoints = [toneCurveControlPoints copy];
    }
    self.toneCurveFilter.RGBCompositeControlPoints = _toneCurveControlPoints;
}

- (void)setRadius:(float)radius {
    _radius = radius;
    _blurFilter.radius = radius;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    MTIImage *bgChannelOverlayImage = [MTIHighPassSkinSmoothingFilter.GBChannelOverlayBlendKernel applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) outputPixelFormat:_outputPixelFormat];
    
    self.blurFilter.inputImage = bgChannelOverlayImage;
    MTIImage *blurredBGChannelOverlayImage = self.blurFilter.outputImage;
    self.blurFilter.inputImage = nil;
    
    return [MTIHighPassSkinSmoothingFilter.maskProcessAndCompositeKernel applyToInputImages:@[self.inputImage, bgChannelOverlayImage, blurredBGChannelOverlayImage, self.toneCurveFilter.toneCurveColorLookupImage] parameters:@{@"amount": @(self.amount)} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) outputPixelFormat:_outputPixelFormat];
}

+ (BOOL)isSupportedOnDevice:(id<MTLDevice>)device {
    return MPSSupportsMTLDevice(device);
}

@end
