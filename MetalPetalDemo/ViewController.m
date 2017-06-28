//
//  ViewController.m
//  MetalPetalDemo
//
//  Created by YuAo on 25/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "ViewController.h"
@import MetalPetal;
@import MetalKit;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSError *error;
    MTIContext *context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    UIImage *image = [UIImage imageNamed:@"P1040602.jpg"];
    
    MTIImage *mtiImageFromCGImage = [[MTIImage alloc] initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:image.CGImage]];
    id<MTLTexture> texture = [context.textureLoader newTextureWithCGImage:image.CGImage options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:&error];
    MTIImage *mtiImageFromTexture = [[MTIImage alloc] initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture]];
    
    MTIColorInvertFilter *filter = [[MTIColorInvertFilter alloc] init];
    filter.inputImage = mtiImageFromTexture;
    MTIImage *outputImage = filter.outputImage;
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, outputImage.size.width, outputImage.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef _Nullable)(@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}}), &pixelBuffer);
    
    while (true) {
        @autoreleasepool {
            CFAbsoluteTime renderPass1Start = CFAbsoluteTimeGetCurrent();
            MTIImageRenderingContext *imageRenderingContext = [[MTIImageRenderingContext alloc] initWithContext:context];
            [imageRenderingContext renderImage:outputImage toPixelBuffer:pixelBuffer error:&error];
            NSLog(@"Time: %@", @(CFAbsoluteTimeGetCurrent() - renderPass1Start));
        }
        [NSThread sleepForTimeInterval:1.0/60.0];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
