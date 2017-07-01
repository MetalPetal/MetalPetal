//
//  ViewController.m
//  MetalPetalDemo
//
//  Created by YuAo on 25/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "ViewController.h"
#import "MetalPetalDemo-Swift.h"
@import MetalPetal;
@import MetalKit;

@interface ViewController () <MTKViewDelegate>

@property (nonatomic, weak) MTKView *renderView;

@property (nonatomic, strong) MTIContext *context;

@property (nonatomic, strong) MTIImage *inputImage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MetalPetalSwiftInterfaceTest test];
    
    NSError *error;
    MTIContext *context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    self.context = context;
    
    UIImage *image = [UIImage imageNamed:@"P1040602.jpg"];
    
    MTKView *renderView = [[MTKView alloc] initWithFrame:self.view.bounds device:context.device];
    renderView.delegate = self;
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:renderView];
    self.renderView = renderView;
    
    
    //MTIImage *mtiImageFromCGImage = [[MTIImage alloc] initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:image.CGImage]];
    
    id<MTLTexture> texture = [context.textureLoader newTextureWithCGImage:image.CGImage options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:&error];
    MTIImage *mtiImageFromTexture = [[MTIImage alloc] initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture]];
    self.inputImage = mtiImageFromTexture;
}

- (void)drawInMTKView:(MTKView *)view {
    MTIColorInvertFilter *filter = [[MTIColorInvertFilter alloc] init];
    filter.inputImage = self.inputImage;
    MTIImage *outputImage = filter.outputImage;
    [self.context renderImage:outputImage toDrawableWithCallback:^id<MTLDrawable> _Nonnull{
        return view.currentDrawable;
    } renderPassDescriptorCallback:^MTLRenderPassDescriptor * _Nonnull{
        return view.currentRenderPassDescriptor;
    } error:nil];
    NSLog(@"draw request");
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
