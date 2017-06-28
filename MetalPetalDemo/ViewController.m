//
//  ViewController.m
//  MetalPetalDemo
//
//  Created by YuAo on 25/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "ViewController.h"
@import MetalPetal;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *image = [UIImage imageNamed:@"P1040602.jpg"];
    NSError *error;
    MTIContext *context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    MTIImage *mtiImage = [[MTIImage alloc] initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:image.CGImage]];
    MTIColorInvertFilter *filter = [[MTIColorInvertFilter alloc] init];
    filter.inputImage = mtiImage;
    mtiImage = filter.outputImage;
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, mtiImage.size.width, mtiImage.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef _Nullable)(@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}}), &pixelBuffer);
    
    {
        CFAbsoluteTime renderPass1Start = CFAbsoluteTimeGetCurrent();
        MTIImageRenderingContext *imageRenderingContext = [[MTIImageRenderingContext alloc] initWithContext:context];
        [imageRenderingContext renderImage:mtiImage toPixelBuffer:pixelBuffer error:&error];
        NSLog(@"Pass 1 time: %@", @(CFAbsoluteTimeGetCurrent() - renderPass1Start));
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
