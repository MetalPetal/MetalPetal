//
//  CameraViewController.m
//  MetalPetalDemo
//
//  Created by jichuan on 2017/7/18.
//  Copyright © 2017年 MetalPetal. All rights reserved.
//

#import "CameraViewController.h"
@import AVFoundation;
@import MetalPetal;

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) MTIImageView *renderView;

@property (nonatomic, strong) MTISaturationFilter *saturationFilter;
@property (nonatomic, strong) MTIColorInvertFilter *colorInvertFilter;
@property (nonatomic, strong) MTIColorLookupFilter *lutFilter;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.renderView = [[MTIImageView alloc] initWithFrame:self.view.bounds];
    self.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.renderView];
    
    self.saturationFilter = [[MTISaturationFilter alloc] init];
    self.colorInvertFilter = [[MTIColorInvertFilter alloc] init];
    self.lutFilter = [[MTIColorLookupFilter alloc] init];

    self.lutFilter.inputColorLookupTable = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"lut_abao"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(YES)}];
    
    self.queue = dispatch_queue_create("video_queue", NULL);
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    for (AVCaptureDevice *videoDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (videoDevice.position == AVCaptureDevicePositionBack) {
            self.videoDevice = videoDevice;
            break;
        }
    }
    
    [self.videoDevice lockForConfiguration:nil];
    if ([self.videoDevice isSmoothAutoFocusSupported]) {
        self.videoDevice.smoothAutoFocusEnabled = YES;
    }
    if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }
    if ([self.videoDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
        self.videoDevice.flashMode = AVCaptureFlashModeOff;
    }
    if ([self.videoDevice isLowLightBoostSupported]) {
        self.videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
    }
    if ([self.videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        self.videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    }
    if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        self.videoDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }
    self.videoDevice.automaticallyAdjustsVideoHDREnabled = YES;
    [self.videoDevice unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:nil];
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.queue];
    [self.videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];
    
    // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    // kCVPixelFormatType_32BGRA
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    }
    
    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self.captureSession commitConfiguration];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.captureSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (CMFormatDescriptionGetMediaType(CMSampleBufferGetFormatDescription(sampleBuffer)) == kCMMediaType_Video) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        MTIImage *inputImage = [[MTIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        self.saturationFilter.inputImage = inputImage;
        self.saturationFilter.saturation = 1.0 + sin(CFAbsoluteTimeGetCurrent() * 2.0);
        self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
        self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
        self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
        self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
        self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
        self.saturationFilter.inputImage = self.colorInvertFilter.outputImage;
        self.colorInvertFilter.inputImage = self.saturationFilter.outputImage;
        MTIImage *outputImage = self.colorInvertFilter.outputImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.renderView.image = outputImage;
        });
    }
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
