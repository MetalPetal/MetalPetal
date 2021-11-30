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
#import "MTIPrint.h"

@interface MTIImageView ()

@property (nonatomic, weak, readonly) MTKView *renderView;

@property (nonatomic) CGFloat screenScale;

@property (nonatomic, strong) NSError *contextCreationError;

@end

@implementation MTIImageView
@synthesize context = _context;

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
    self.accessibilityIgnoresInvertColors = YES;
    
    _resizingMode = MTIDrawableRenderingResizingModeAspect;
    _automaticallyCreatesContext = YES;
    
    MTKView *renderView = [[MTKView alloc] initWithFrame:self.bounds device:nil];
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderView.delegate = self;
    renderView.paused = YES;
    renderView.enableSetNeedsDisplay = YES;
    renderView.contentMode = self.contentMode;
    [self addSubview:renderView];
    _renderView = renderView;
    _drawsImmediately = NO;
    
    self.opaque = YES;
}

- (void)setDrawsImmediately:(BOOL)drawsImmediately {
    _drawsImmediately = drawsImmediately;
    MTKView *renderView = _renderView;
    if (drawsImmediately) {
        renderView.paused = YES;
        renderView.enableSetNeedsDisplay = NO;
    } else {
        renderView.paused = YES;
        renderView.enableSetNeedsDisplay = YES;
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window.screen) {
        _screenScale = MIN(self.window.screen.nativeScale, self.window.screen.scale);
    } else {
        _screenScale = 1.0;
    }
}

- (void)setContext:(MTIContext *)context {
    _context = context;
    _renderView.device = context.device;
}

- (MTIContext *)context {
    [self setupContextIfNeeded];
    return _context;
}

- (void)setupContextIfNeeded {
    if (!_context && !_contextCreationError && _automaticallyCreatesContext) {
        NSError *error;
        _context = [[MTIContext alloc] initWithDevice:MTLCreateSystemDefaultDevice() error:&error];
        if (error) {
            _contextCreationError = error;
        }
        _renderView.device = _context.device;
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    _renderView.contentMode = contentMode;
}

- (void)setOpaque:(BOOL)opaque {
    BOOL oldOpaque = [super isOpaque];
    [super setOpaque:opaque];
    MTKView *renderView = _renderView;
    renderView.opaque = opaque;
    renderView.layer.opaque = opaque;
    if (oldOpaque != opaque) {
        [self setNeedsRedraw];
    }
}

- (void)setHidden:(BOOL)hidden {
    BOOL oldHidden = [super isHidden];
    [super setHidden:hidden];
    if (oldHidden) {
        [self setNeedsRedraw];
    }
}

- (void)setAlpha:(CGFloat)alpha {
    CGFloat oldAlpha = [super alpha];
    [super setAlpha:alpha];
    if (oldAlpha <= 0) {
        [self setNeedsRedraw];
    }
}

- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat {
    MTKView *renderView = _renderView;
    MTLPixelFormat oldColorPixelFormat = renderView.colorPixelFormat;
    renderView.colorPixelFormat = colorPixelFormat;
    if (oldColorPixelFormat != colorPixelFormat) {
        [self setNeedsRedraw];
    }
}

- (MTLPixelFormat)colorPixelFormat {
    return _renderView.colorPixelFormat;
}

- (void)setClearColor:(MTLClearColor)clearColor {
    MTKView *renderView = _renderView;
    MTLClearColor oldClearColor = renderView.clearColor;
    renderView.clearColor = clearColor;
    if (oldClearColor.red != clearColor.red ||
        oldClearColor.green != clearColor.green ||
        oldClearColor.blue != clearColor.blue ||
        oldClearColor.alpha != clearColor.alpha) {
        [self setNeedsRedraw];
    }
}

- (MTLClearColor)clearColor {
    return _renderView.clearColor;
}

- (void)updateContentScaleFactor {
    MTKView *renderView = _renderView;
    if (renderView.frame.size.width > 0 && renderView.frame.size.height > 0 && _image && _image.size.width > 0 && _image.size.height > 0 && self.window.screen != nil) {
        CGSize imageSize = _image.size;
        CGFloat widthScale = imageSize.width/renderView.bounds.size.width;
        CGFloat heightScale = imageSize.height/renderView.bounds.size.height;
        CGFloat nativeScale = _screenScale;
        CGFloat scale = MAX(MIN(MAX(widthScale,heightScale),nativeScale), 1.0);
        if (ABS(renderView.contentScaleFactor - scale) > 0.00001) {
            renderView.contentScaleFactor = scale;
        }
    }
}

- (void)setImage:(MTIImage *)image {
    NSAssert(NSThread.isMainThread, @"-[MTIImageView setImage:] can only be called on main thread.");
    if (_image != image) {
        _image = image;
        [self updateContentScaleFactor];
        [self setNeedsRedraw];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateContentScaleFactor];
    [self setNeedsRedraw];
}

- (void)setNeedsRedraw {
    MTKView *renderView = _renderView;
    if (_drawsImmediately) {
        [renderView draw];
    } else {
        [renderView setNeedsDisplay];
    }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        if (!self.isHidden && self.alpha > 0) {
            [self setupContextIfNeeded];
            
            MTIContext *context = _context;
            if (!context) {
                return;
            }
            MTIImage *imageToRender = _image;
            if (imageToRender) {
                MTIDrawableRenderingRequest *request = [[MTIDrawableRenderingRequest alloc] initWithDrawableProvider:view resizingMode:_resizingMode];
                NSError *error;
                [context renderImage:imageToRender toDrawableWithRequest:request error:&error];
                if (error) {
                    MTIPrint(@"%@: Failed to render image %@ - %@",self,imageToRender,error);
                }
            } else {
                //Clear current drawable.
                MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
                id<MTLDrawable> drawable = view.currentDrawable;
                if (renderPassDescriptor && drawable) {
                    id<MTLCommandBuffer> commandBuffer = [context.commandQueue commandBuffer];
                    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                    [commandEncoder endEncoding];
                    [commandBuffer presentDrawable:drawable];
                    [commandBuffer commit];
                }
            }
        }
    }
}

@end

#endif
