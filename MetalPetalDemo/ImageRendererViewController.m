//
//  ViewController.m
//  MetalPetalDemo
//
//  Created by YuAo on 25/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "ImageRendererViewController.h"
#import <sys/kdebug_signpost.h>
@import MetalPetal;
@import MetalKit;

@interface ImageRendererViewController () <MTKViewDelegate>

@property (nonatomic, weak) MTKView *renderView;

@property (nonatomic, strong) MTIContext *context;

@property (nonatomic, strong) MTIImage *inputImage;

@property (nonatomic, strong) MTISaturationFilter *saturationFilter;

@property (nonatomic, strong) MTIColorInvertFilter *colorInvertFilter;

@property (nonatomic, strong) MTIColorMatrixFilter *colorMatrixFilter;

@property (nonatomic, strong) MTIExposureFilter *exposureFilter;

@property (nonatomic, strong) MTIImage *cachedImage;

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *blurFilter;

@property (nonatomic, strong) MTIMultilayerCompositingFilter *compositingFilter;

@property (nonatomic, strong) MTIHexagonalBokehBlurFilter *lensBlurFilter;

@property (nonatomic, strong) MTICLAHEFilter *claheFilter;

@property (nonatomic, strong) MTIBlendFilter *blendFilter;

@property (nonatomic, strong)  MTIBlendWithMaskFilter *maskBlendFilter;

@property (nonatomic, strong)  MTIVibranceFilter *vibranceFilter;
@end

@implementation ImageRendererViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.redColor;
    
    MTIContextOptions *options = [[MTIContextOptions alloc] init];
    //options.enablesRenderGraphOptimization = NO;
    //options.workingPixelFormat = MTLPixelFormatRGBA16Float;
    
    NSError *error;
    MTIContext *context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() options:options error:&error];
    self.context = context;
    
    UIImage *image = [UIImage imageNamed:@"P1040808.jpg"];
    
    MTKView *renderView = [[MTKView alloc] initWithFrame:self.view.bounds device:context.device];
    renderView.delegate = self;
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderView.layer.opaque = NO;
    [self.view addSubview:renderView];
    self.renderView = renderView;
    
    self.saturationFilter = [[MTISaturationFilter alloc] init];
    self.colorInvertFilter = [[MTIColorInvertFilter alloc] init];
    self.colorMatrixFilter = [[MTIColorMatrixFilter alloc] init];
    self.exposureFilter = [[MTIExposureFilter alloc] init];
    self.blurFilter = [[MTIMPSGaussianBlurFilter  alloc] init];
    self.compositingFilter = [[MTIMultilayerCompositingFilter alloc] init];
    self.lensBlurFilter = [[MTIHexagonalBokehBlurFilter alloc] init];
    self.claheFilter = [[MTICLAHEFilter alloc] init];
    
    self.maskBlendFilter = [[MTIBlendWithMaskFilter alloc] init];
    
    self.maskBlendFilter.inputMask = [[MTIMask alloc] initWithContent:[[[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"metal_mask_blend_mask"].CGImage loadingOptions:nil] imageByUnpremultiplyingAlpha] component:MTIColorComponentAlpha mode:MTIMaskModeOneMinusMaskValue];
    
    self.maskBlendFilter.inputImage = [[[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_source"].CGImage loadingOptions:nil] imageByUnpremultiplyingAlpha];
    self.maskBlendFilter.inputBackgroundImage = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_background"].CGImage loadingOptions:nil isOpaque:YES];
    
    self.vibranceFilter = [[MTIVibranceFilter alloc] init];
    self.vibranceFilter.avoidsSaturatingSkinTones = YES;
    
    self.inputImage = [[MTIImage alloc] initWithCGImage:image.CGImage loadingOptions:nil isOpaque:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.renderView.contentScaleFactor = self.view.window.screen.nativeScale;
}

- (MTIImage *)maskBlendTestOutputImage {
    MTIImage *outputImage = self.maskBlendFilter.outputImage;
    return outputImage;
}

- (MTIImage *)vibranceTestOutputImage {
    float amount =  sin(CFAbsoluteTimeGetCurrent() * 2.0) ;
    self.vibranceFilter.inputImage = self.inputImage;
    self.vibranceFilter.amount = amount;
    MTIImage *outputImage = self.vibranceFilter.outputImage;
    return outputImage;
}

- (MTIImage *)saturationTestOutputImage {
    self.saturationFilter.inputImage = self.inputImage;
    self.saturationFilter.saturation = 1.0 + sin(CFAbsoluteTimeGetCurrent() * 2.0);
    MTIImage *outputImage = self.saturationFilter.outputImage;
    return outputImage;
}

- (MTIImage *)colorMatrixTestOutputImage {
    float scale = sin(CFAbsoluteTimeGetCurrent() * 2.0) + 1.0;
    self.colorMatrixFilter.colorMatrix = MTIColorMatrixMakeWithExposure(scale);
    self.colorMatrixFilter.inputImage = self.inputImage;
    MTIImage *outputImage = self.colorMatrixFilter.outputImage;
    return outputImage;
}

- (MTIImage *)lensBlurTestOutputImage {
    self.lensBlurFilter.brightness = 0.3;
    self.lensBlurFilter.radius = 10 * (1.0 + sin(CFAbsoluteTimeGetCurrent() * 2.0));
    self.lensBlurFilter.inputImage = self.inputImage;
    MTIImage *outputImage = self.lensBlurFilter.outputImage;
    return outputImage;
}

- (MTIImage *)claheTestOutputImage {
    self.claheFilter.inputImage = self.inputImage;
    return self.claheFilter.outputImage;
}

- (MTIImage *)renderTargetCacheAndReuseTestOutputImage {
    MTIImage *inputImage = self.inputImage;
    self.saturationFilter.inputImage = inputImage;
    self.saturationFilter.saturation = 2.0;
    
    MTIImage *saturatedImage = self.cachedImage;
    if (!saturatedImage) {
        saturatedImage = [self.saturationFilter.outputImage imageWithCachePolicy:MTIImageCachePolicyPersistent];
        self.cachedImage = saturatedImage;
    }
    
    self.colorInvertFilter.inputImage = saturatedImage;
    self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
    self.saturationFilter.saturation = 0.0;
    //self.saturationFilter.inputImage = self.saturationFilter.outputImage;
    MTIImage *invertedAndDesaturatedImage = self.saturationFilter.outputImage;
    
    self.saturationFilter.saturation = 0.0;
    self.saturationFilter.inputImage = saturatedImage;
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    self.colorInvertFilter.inputImage = self.colorInvertFilter.outputImage;
    MTIImage *desaturatedAndInvertedImage = self.colorInvertFilter.outputImage;
    
    self.blendFilter.inputBackgroundImage = desaturatedAndInvertedImage;
    self.blendFilter.inputImage = invertedAndDesaturatedImage;
    return self.blendFilter.outputImage;
}

- (MTIImage *)multilayerCompositingTestOutputImage {
    self.compositingFilter.inputBackgroundImage = self.inputImage;

    static MTIImage *maskImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        maskImage = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"metal_mask_blend_mask"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(NO)}];
    });
    
    self.compositingFilter.layers = @[
                                      [[MTILayer alloc] initWithContent:self.inputImage contentRegion:CGRectMake(0, 0, 960, 540) contentFlipOptions:MTILayerFlipOptionsFlipVertically compositingMask:
                                        [[MTIMask alloc] initWithContent:maskImage component:MTIColorComponentRed mode:MTIMaskModeNormal] layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(200, 200) size:CGSizeMake(1920, 1080) rotation:0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(900, 900) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeNormal],
                                      [[MTILayer alloc] initWithContent:self.inputImage layoutUnit:MTILayerLayoutUnitPixel position:CGPointMake(600, 600) size:CGSizeMake(1920/3.0, 1080/3.0) rotation:-3.14/4.0 opacity:1 blendMode:MTIBlendModeOverlay]
                                      ];
    self.saturationFilter.inputImage = self.compositingFilter.outputImage;
    return self.saturationFilter.outputImage;
}

- (MTIImage *)blendFilterTestOutputImage
{
    return self.blendFilter.outputImage;
}

#pragma mark ----------
- (void)drawInMTKView:(MTKView *)view {
    //https://developer.apple.com/library/content/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
    @autoreleasepool {
        kdebug_signpost_start(1, 0, 0, 0, 1);
        MTIImage *outputImage = [self saturationTestOutputImage];
        MTIDrawableRenderingRequest *request = [[MTIDrawableRenderingRequest alloc] initWithDrawableProvider:view resizingMode:MTIDrawableRenderingResizingModeAspect];
        NSError *error;
        [self.context renderImage:outputImage toDrawableWithRequest:request error:&error];
        kdebug_signpost_end(1, 0, 0, 0, 1);
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

@end

