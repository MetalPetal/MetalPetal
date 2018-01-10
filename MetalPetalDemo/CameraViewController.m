//
//  CameraViewController.m
//  MetalPetalDemo
//
//  Created by jichuan on 2017/7/18.
//  Copyright © 2017年 MetalPetal. All rights reserved.
//

#import "CameraViewController.h"
#import "MetalPetalDemo-Swift.h"
@import AVFoundation;
@import MetalPetal;

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) Camera *camera;

@property (nonatomic, strong) MTIImageView *renderView;

@property (nonatomic, strong) MTISaturationFilter *saturationFilter;
@property (nonatomic, strong) MTIColorInvertFilter *colorInvertFilter;
@property (nonatomic, strong) MTIColorLookupFilter *colorLookupFilter;
@property (nonatomic, strong) MTICropFilter *cropFilter;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.renderView = [[MTIImageView alloc] initWithFrame:self.view.bounds];
    self.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.renderView];

    self.cropFilter = [[MTICropFilter alloc] init];
    self.cropFilter.scale = 0.1;
    
    self.saturationFilter = [[MTISaturationFilter alloc] init];
    self.colorInvertFilter = [[MTIColorInvertFilter alloc] init];
    self.colorLookupFilter = [[MTIColorLookupFilter alloc] init];

    self.colorLookupFilter.inputColorLookupTable = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"ColorTableGraded"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} alphaType:MTIAlphaTypeAlphaIsOne];
    
    self.camera = [[Camera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    [self.camera enableVideoDataOutputWithSampleBufferDelegate:self queue:dispatch_queue_create("com.metalpetal.MetalPetalDemo.videoCallback", DISPATCH_QUEUE_SERIAL)];
    [self.camera.videoDataOuput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
    // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    // kCVPixelFormatType_32BGRA
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.camera startRunningCaptureSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.camera stopRunningCaptureSession];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (CMFormatDescriptionGetMediaType(CMSampleBufferGetFormatDescription(sampleBuffer)) == kCMMediaType_Video) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        MTIImage *inputImage = [[MTIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        self.colorLookupFilter.inputImage = inputImage;
        MTIImage *outputImage = self.colorLookupFilter.outputImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.renderView.image = outputImage;
        });
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
