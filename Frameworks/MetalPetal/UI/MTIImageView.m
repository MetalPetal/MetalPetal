//
//  MTIImageView.m
//  Pods
//
//  Created by Yu Ao on 09/10/2017.
//

#if __has_include(<UIKit/UIKit.h>)

#import "MTIImageView.h"
#import "MTIContext+Rendering.h"
#import "MTIImage.h"
#import <MetalKit/MetalKit.h>

@interface MTIImageView () <MTKViewDelegate>

@property (nonatomic,weak) MTKView *renderView;

@end

@implementation MTIImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupImageView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupImageView];
    }
    return self;
}

- (void)setupImageView {
    if (@available(iOS 11.0, *)) {
        self.accessibilityIgnoresInvertColors = YES;
    }
    self.opaque = YES;
    _resizingMode = MTIDrawableRenderingResizingModeAspect;
    NSError *error;
    _context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
    if (error) {
        NSLog(@"%@: Failed to create MTIContext - %@",self,error);
    }
    MTKView *renderView = [[MTKView alloc] initWithFrame:self.frame device:_context.device];
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderView.enableSetNeedsDisplay = YES;
    renderView.delegate = self;
    [self addSubview:renderView];
    _renderView = renderView;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        _renderView.contentScaleFactor = self.window.screen.nativeScale;
    }
}

- (void)setContext:(MTIContext *)context {
    _context = context;
    _renderView.device = context.device;
}

- (void)setOpaque:(BOOL)opaque {
    [super setOpaque:opaque];
    _renderView.opaque = opaque;
    _renderView.layer.opaque = opaque;
}

- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat {
    _renderView.colorPixelFormat = colorPixelFormat;
}

- (MTLPixelFormat)colorPixelFormat {
    return _renderView.colorPixelFormat;
}

- (void)setClearColor:(MTLClearColor)clearColor {
    _renderView.clearColor = clearColor;
}

- (MTLClearColor)clearColor {
    return _renderView.clearColor;
}

- (void)setImage:(MTIImage *)image {
    _image = image;
    [self.renderView setNeedsDisplay];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        if (_image) {
            NSAssert(_context != nil, @"Context is nil.");
            MTIDrawableRenderingRequest *request = [[MTIDrawableRenderingRequest alloc] init];
            request.drawableProvider = _renderView;
            request.resizingMode = _resizingMode;
            NSError *error;
            [_context renderImage:_image toDrawableWithRequest:request error:&error];
            if (error) {
                NSLog(@"%@: Failed to render image %@ - %@",self,_image,error);
            }
        }
    }
}

@end

#endif
