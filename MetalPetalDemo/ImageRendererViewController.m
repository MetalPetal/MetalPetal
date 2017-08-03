//
//  ViewController.m
//  MetalPetalDemo
//
//  Created by YuAo on 25/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "ImageRendererViewController.h"
#import "MetalPetalDemo-Swift.h"
#import "WeakToStrongObjectsMapTableTests.h"
#import "CameraViewController.h"
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

@property (nonatomic, strong) MTIOverlayBlendFilter *overlayBlendFilter;

@property (nonatomic, strong) MTIImage *cachedImage;

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *blurFilter;

@end

@implementation ImageRendererViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[MetalPetalSwiftInterfaceTest test];
    
    //[WeakToStrongObjectsMapTableTests test];

    NSError *error;
    MTIContext *context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    self.context = context;
    
    UIImage *image = [UIImage imageNamed:@"P1040808.jpg"];
    
    MTKView *renderView = [[MTKView alloc] initWithFrame:self.view.bounds device:context.device];
    renderView.delegate = self;
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:renderView];
    self.renderView = renderView;
    
    self.saturationFilter = [[MTISaturationFilter alloc] init];
    self.colorInvertFilter = [[MTIColorInvertFilter alloc] init];
    self.colorMatrixFilter = [[MTIColorMatrixFilter alloc] init];
    self.overlayBlendFilter = [[MTIOverlayBlendFilter alloc] init];
    self.blurFilter = [[MTIMPSGaussianBlurFilter  alloc] init];
    //MTIImage *mtiImageFromCGImage = [[MTIImage alloc] initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:image.CGImage]];
    
    id<MTLTexture> texture = [context.textureLoader newTextureWithCGImage:image.CGImage options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:&error];
    MTIImage *mtiImageFromTexture = [[MTIImage alloc] initWithTexture:texture];
    self.inputImage = mtiImageFromTexture;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (MTIImage *)saturationAndInvertTestOutputImage {
    self.saturationFilter.inputImage = self.inputImage;
    self.saturationFilter.saturation = 1.0 + sin(CFAbsoluteTimeGetCurrent() * 2.0);
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    MTIImage *outputImage = self.colorInvertFilter.outputImage;
    return outputImage;
}

- (MTIImage *)colorMatrixTestOutputImage {
    float scale = sin(CFAbsoluteTimeGetCurrent() * 2.0) + 1.0;
    self.colorMatrixFilter.colorMatrix = matrix_scale(scale, matrix_identity_float4x4);
    self.colorMatrixFilter.inputImage = self.inputImage;
    MTIImage *outputImage = self.colorMatrixFilter.outputImage;
    return outputImage;
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
    MTIImage *invertedAndDesaturatedImage = self.saturationFilter.outputImage;
    
    self.saturationFilter.saturation = 0.0;
    self.saturationFilter.inputImage = saturatedImage;
    self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
    MTIImage *desaturatedAndInvertedImage = self.colorInvertFilter.outputImage;
    
    self.overlayBlendFilter.inputBackgroundImage = desaturatedAndInvertedImage;
    self.overlayBlendFilter.inputForegroundImage = invertedAndDesaturatedImage;
    return self.overlayBlendFilter.outputImage;
}

- (void)drawInMTKView:(MTKView *)view {
    //https://developer.apple.com/library/content/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
    @autoreleasepool {
        kdebug_signpost_start(1, 0, 0, 0, 1);
        self.blurFilter.inputImage = self.inputImage;
        self.blurFilter.radius = 20.0;
        MTIImage *outputImage = self.blurFilter.outputImage;
        MTIDrawableRenderingRequest *request = [[MTIDrawableRenderingRequest alloc] init];
        request.drawableProvider = self.renderView;
        request.resizingMode = MTIDrawableRenderingResizingModeAspect;
        [self.context renderImage:outputImage toDrawableWithRequest:request error:nil];
        kdebug_signpost_start(1, 0, 0, 0, 1);
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end

