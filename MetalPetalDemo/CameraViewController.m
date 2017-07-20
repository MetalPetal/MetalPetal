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

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate>

@property (nonatomic, strong) MTIContext *context;

@property (nonatomic, strong) MTKView *renderView;

@property (nonatomic, strong) MTISaturationFilter *saturationFilter;
@property (nonatomic, strong) MTIColorInvertFilter *colorInvertFilter;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@end

@implementation CameraViewController

- (void)dealloc
{
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
        self.pixelBuffer = NULL;
    }
}

- (instancetype)initWithMTIContext:(MTIContext *)context
{
    self = [super init];
    if (self) {
        self.context = context;
        self.pixelBuffer = NULL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.renderView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.context.device];
    self.renderView.delegate = self;
    self.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.renderView];
    
    self.saturationFilter = [[MTISaturationFilter alloc] init];
    self.colorInvertFilter = [[MTIColorInvertFilter alloc] init];
    
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

        CVPixelBufferRef pixelBuffer = CVPixelBufferRetain(CMSampleBufferGetImageBuffer(sampleBuffer));
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.pixelBuffer) {
                CVPixelBufferRelease(self.pixelBuffer);
                self.pixelBuffer = NULL;
            }
            self.pixelBuffer = pixelBuffer;
        });
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    if (self.renderView.currentDrawable && self.renderView.currentRenderPassDescriptor && self.pixelBuffer) {
        MTIImage *inputImage = [[MTIImage alloc] initWithCVPixelBuffer:self.pixelBuffer];
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
        MTIDrawableRenderingRequest *request = [[MTIDrawableRenderingRequest alloc] init];
        request.drawableProvider = self.renderView;
        request.resizingMode = MTIDrawableRenderingResizingModeAspect;
        [self.context renderImage:outputImage toDrawableWithRequest:request error:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
