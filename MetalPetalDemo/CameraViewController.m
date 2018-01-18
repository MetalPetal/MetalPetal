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
@import AVKit;

static CMSampleBufferRef SampleBufferByReplacingImageBuffer(CMSampleBufferRef sampleBuffer, CVPixelBufferRef imageBuffer) {
    CMSampleTimingInfo timeingInfo;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timeingInfo);
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMFormatDescriptionRef formatDescription;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, imageBuffer, &formatDescription);
    CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBuffer, formatDescription, &timeingInfo, &outputSampleBuffer);
    CFRelease(formatDescription);
    return (CMSampleBufferRef)CFAutorelease(outputSampleBuffer);
}

NSString * const CameraViewControllerCapturedVideosFolderName = @"videos";

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong, readonly) Camera *camera;

@property (nonatomic, strong) Recorder *recorder;

@property (nonatomic) CVPixelBufferPoolRef pixelBufferPool;

@property (nonatomic, weak, readonly) MTIImageView *renderView;

@property (nonatomic, strong, readonly) MTIContext *context;

@property (nonatomic, copy) NSURL *currentVideoURL;

@property (atomic, getter=isFilterEnabled) BOOL filterEnabled;

@property (nonatomic, strong) MTIColorLookupFilter *colorLookupFilter;
@property (nonatomic, strong) MTIVibranceFilter *vibranceFilter;
@property (nonatomic, strong) MTIPixellateFilter *pixellateFilter;
@property (nonatomic, strong) MTIColorHalftoneFilter *halftoneFilter;
@property (nonatomic, strong) MTIDotScreenFilter *dotScreenFilter;

@end

@implementation CameraViewController

- (void)dealloc {
    CVPixelBufferPoolRelease(_pixelBufferPool);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:CameraViewControllerCapturedVideosFolderName] error:nil];
    [fileManager createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:CameraViewControllerCapturedVideosFolderName] withIntermediateDirectories:YES attributes:nil error:nil];
    
    _filterEnabled = YES;
    
    NSError *error;
    _context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    NSAssert(error == nil, @"Error creating context");
    
    MTIImageView *renderView = [[MTIImageView alloc] initWithFrame:self.view.bounds];
    renderView.context = _context;
    renderView.drawsImmediately = NO;
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:renderView atIndex:0];
    _renderView = renderView;
    
    _vibranceFilter = [[MTIVibranceFilter alloc] init];
    _vibranceFilter.amount = 1.0;
    
    _pixellateFilter = [[MTIPixellateFilter alloc] init];
    
    _colorLookupFilter = [[MTIColorLookupFilter alloc] init];
    _colorLookupFilter.inputColorLookupTable = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"ColorLookup512"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} alphaType:MTIAlphaTypeAlphaIsOne];
    
    _halftoneFilter = [[MTIColorHalftoneFilter alloc] init];
    
    _dotScreenFilter = [[MTIDotScreenFilter alloc] init];
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault,
                            (__bridge CFDictionaryRef)@{(id)kCVPixelBufferPoolMinimumBufferCountKey: @(30)},
                            (__bridge CFDictionaryRef)@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
                                                        (id)kCVPixelBufferWidthKey: @(1080),
                                                        (id)kCVPixelBufferHeightKey: @(1920),
                                                        (id)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                            &_pixelBufferPool);
    NSAssert(_pixelBufferPool, @"");
    
    _camera = [[Camera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    [_camera enableVideoDataOutputWithSampleBufferDelegate:self queue:dispatch_queue_create("com.metalpetal.MetalPetalDemo.videoCallback", DISPATCH_QUEUE_SERIAL)];
    [_camera.videoDataOuput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
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

- (IBAction)recordButtonTouchDown:(id)sender {
    self.currentVideoURL = [[[[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:CameraViewControllerCapturedVideosFolderName] URLByAppendingPathComponent:[NSUUID UUID].UUIDString] URLByAppendingPathExtension:@"mp4"];
    self.recorder = [[Recorder alloc] initWithOutputURL:self.currentVideoURL];
    [self.recorder startRecording];
}

- (IBAction)recordButtonTouchUp:(id)sender {
    self.view.userInteractionEnabled = NO;
    [self.recorder stopRecordingWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            
            AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
            AVPlayer *player = [AVPlayer playerWithURL:self.currentVideoURL];
            playerViewController.player = player;
            [self presentViewController:playerViewController animated:YES completion:^{
                [player play];
            }];
        });
    }];
}

- (IBAction)filterSwitchValueChanged:(UISwitch *)sender {
    self.filterEnabled = sender.isOn;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (CMFormatDescriptionGetMediaType(CMSampleBufferGetFormatDescription(sampleBuffer)) == kCMMediaType_Video) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CMSampleBufferRef outputSampleBuffer = sampleBuffer;

        MTIImage *inputImage = [[MTIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        MTIImage *outputImage = inputImage;
        if (self.isFilterEnabled) {
            self.colorLookupFilter.inputImage = inputImage;
            outputImage = [self.colorLookupFilter.outputImage imageWithCachePolicy:MTIImageCachePolicyPersistent];
            
            /// render output image to pixelbuffer
            CVPixelBufferRef outputPixelBuffer;
            // Fetch a CVPixelBuffer from CVPixelBufferPool or create a CVPixelBuffer.
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferPool, &outputPixelBuffer);
            CFAutorelease(outputPixelBuffer);
            
            // Render the outpput image to the pixel buffer.
            NSError *error;
            [self.context renderImage:outputImage toCVPixelBuffer:outputPixelBuffer error:&error];
            NSAssert(error == nil, @"");
            
            outputSampleBuffer = SampleBufferByReplacingImageBuffer(sampleBuffer, outputPixelBuffer);
        }
  
        //Encode
        [self.recorder appendSampleBuffer:outputSampleBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //preview output image
            self.renderView.image = outputImage;
        });
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
