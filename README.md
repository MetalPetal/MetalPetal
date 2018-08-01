# MetalPetal

An image processing framework based on Metal.

- [Design Overview](#design-overview)
    - [Goals](#goals)
    - [Core Components](#core-components)
        - [MTIContext](#mticontext)
        - [MTIImage](#mtiimage)
        - [MTIFilter](#mtifilter)
        - [MTIKernel](#mtikernel)
    - [Alpha Type Handling](#alpha-type-handling)
    - [Optimizations](#optimizations)
    - [Concurrency Considerations](#concurrency-considerations)
    - [Advantages over Core Image](#advantages-over-core-image)
- [Builtin Filters](#builtin-filters)
- [Example Code](#example-code)
    - [Create a `MTIImage`](#create-a-mtiimage)
    - [Create a filtered image](#create-a-filtered-image)
    - [Render a `MTIImage`](#render-a-mtiimage)
- [Quick Look Debug Support](#quick-look-debug-support)
- [Best Practices](#best-practices)
- [Build Custom Filter](#build-custom-filter)
    - [Simple single input/output filters](#simple-single-inputoutput-filters)
    - [Fully custom filters](#fully-custom-filters)
    - [Multiple draw calls in one render pass](#multiple-draw-calls-in-one-render-pass)
- [Install](#install)
- [Contribute](#contribute)
- [License](#license)

## Design Overview

MetalPetal is an image processing framework based on [Metal](https://developer.apple.com/metal/) designed to provide real-time processing for still image and video with easy to use programming interfaces.

This chapter covers the key concepts of MetalPetal, and will help you to get a better understanding of its design, implementation, performance implications and best practices.

### Goals

MetalPetal is designed with the following goals in mind.

- Easy to use API

    Provides convenience APIs and avoids common pitfalls.

- Performance

    Use CPU, GPU and memory efficiently.

- Extensibility

    Easy to create custom filters as well as plugin your custom image processing unit.

- Swifty

    Provides a fluid experience for Swift programmers.

### Core Components

Some of the core concepts of MetalPetal are very similar to those in Apple's Core Image framework.

#### MTIContext

Provides an evaluation context for rendering `MTIImage`s. It also stores a lot of caches and state information, so it's more efficient to reuse a context whenever possible.

#### MTIImage

 A `MTIImage` object is a representation of an image to be processed or produced. It does directly represent image bitmap data instead it has all the information necessary to produce an image or more precisely a `MTLTexture`. It consists of two parts, a recipe of how to produce the texture (`MTIImagePromise`) and other information such as how a context caches the image (`cachePolicy`), and how the texture should be sampled (`samplerDescriptor`).

#### MTIFilter

A `MTIFilter` represents an image processing effect and any parameters that control that effect. It produces a `MTIImage` object as output. To use a filter, you create a filter object, set its input images and parameters, and then access its output image. Typically, a filter class owns a static kernel (`MTIKernel`), when you access its `outputImage` property, it asks the kernel with the input images and parameters to produce a output `MTIImage`. 

#### MTIKernel

A `MTIKernel` represents an image processing routine. `MTIKernel` is responsible for creating the cooresponding render or compute pipeline state for the filter, as well as building the `MTIImagePromise` for a `MTIImage`.

### Alpha Type Handling

If an alpha channel is used in an image, there are two common representations that are available: unpremultiplied (straight/unassociated) alpha, and premultiplied (associated) alpha.

With unpremultiplied alpha, the RGB components represent the color of the pixel, disregarding its opacity.

With premultiplied alpha, the RGB components represent the color of the pixel, adjusted for its opacity by multiplication.

Most of the filters in MetalPetal accept unpremultiplied alpha and opaque images and output unpremultiplied alpha images. Some filters, such as  `MTIMultilayerCompositingFilter` accepts both unpremultiplied/premultiplied alpha images.

MetalPetal handles alpha type explicitly. You are responsible for providing the correct alpha type during image creation.

There are three alpha types in MetalPetal.

`MTIAlphaType.nonPremultiplied`: the alpha value in the image is not premultiplied.

`MTIAlphaType.premultiplied`: the alpha value in the image is premultiplied.

`MTIAlphaType.alphaIsOne`: there's no alpha channel in the image or the image is opaque.

Typically, `CGImage`, `CVPixelBuffer`, `CIImage` objects have premultiplied alpha channel. `MTIAlphaType.alphaIsOne` is strongly recommanded if the image is opaque, e.g. a `CVPixelBuffer` from camera feed, or a `CGImage` loaded from a `jpg` file.

You can call `unpremultiplyingAlpha()` or `premultiplyingAlpha()` on a `MTIImage` to convert the alpha type of the image.

For performance reasons, alpha type validation only happens in debug build.

### Optimizations

MetalPetal does a lot of optimizations for you under the hood.

It automatically caches functions, kernel states, samplers, etc.

Before rendering, MetalPetal can look into your image render graph and figure out the minimal number of intermedinate textures needed to do the rendering, saving memory, energy and time.

It can also re-organize the image render graph if multiple “recipes” can be concatenated to eliminate redundant render passes. (`MTIContext.isRenderGraphOptimizationEnabled`)

### Concurrency Considerations

`MTIImage` objects are immutable, which means they can be shared safely among threads.

However, `MTIFilter` objects are mutable and thus cannot be shared safely among threads.

A `MTIContext` contains a lot of states and caches. There's a thread-safe mechanism for `MTIContext` objects, making it safe to share a `MTIContext` object among threads.

### Advantages over Core Image

- Fully customizable vertex and fragment functions.

- MRT (Multiple Render Targets) support.

- Generally better performance. (Detailed benchmark data needed)

## Builtin Filters

- Color Matrix

- Color Lookup

    Uses an color lookup table to remap the colors in an image.

- Opacity

- Exposure

- Saturation

- Brightness

- Contrast

- Color Invert

- Vibrance

    Adjusts the saturation of an image while keeping pleasing skin tones.

- RGB Tone Curve

- Blend Modes

    - Normal
    - Multiply
    - Overlay
    - Screen
    - HardLight
    - SoftLight
    - Darken
    - Lighten
    - ColorDodge
    - Difference
    - Exclusion
    - Hue
    - Saturation
    - Color
    - Luminosity
    - ColorLookup512x512

- Blend with Mask

- Transform

- Crop

- Pixellate

- Multilayer Composite

- MPS Convolution

- MPS Gaussian Blur

- High Pass Skin Smoothing

- CLAHE (Contrast-Limited Adaptive Histogram Equalization)

- Lens Blur (Hexagonal Bokeh Blur)

## Example Code

### Create a `MTIImage`

```Swift
let imageFromCGImage = MTIImage(cgImage: cgImage, options: [.SRGB: false])

let imageFromCIImage = MTIImage(ciImage: ciImage)

let imageFromCoreVideoPixelBuffer = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)

let imageFromContentsOfURL = MTIImage(contentsOf: url, options: [.SRGB: false])
```

### Create a filtered image

```Swift
let inputImage = ...

let filter = MTISaturationFilter()
filter.saturation = 0
filter.inputImage = inputImage

let outputImage = filter.outputImage
```

### Render a `MTIImage`

```Swift
let options = MTIContextOptions()

guard let device = MTLCreateSystemDefaultDevice(), let context = try? MTIContext(device: device, options: options) else {
    return
}

let image: MTIImage = ...

do {
    try context.render(image, to: pixelBuffer) 
    
    //context.makeCIImage(from: image)
    
    //context.makeCGImage(from: image)
} catch {
    print(error)
}
```

## Quick Look Debug Support

If you do a Quick Look on a `MTIImage`, it'll show you the image graph that you constructed to produce that image.

![Quick Look Debug Preview](https://github.com/MetalPetal/MetalPetal/blob/master/Assets/quick_look_debug_preview.jpg)

## Best Practices

- Reuse a `MTIContext` whenever possible.

    Contexts are heavyweight objects, so if you do create one, do so as early as possible, and reuse it each time you need to render an image.

- Use `MTIImage.cachePolicy` wisely.
    
    Use `MTIImageCachePolicyTransient` when you do not want to preserve the render result of a image, for example when the image is just an intermediate result in a filter chain, so the underlying texture of the render result can be reused. It is the most memory efficient option. However, when you ask the context to render a previously rendered image, it may re-render that image since its underlying texture has been reused.
    
    By default, a filter's output image has the `transient` policy.

    Use `MTIImageCachePolicyPersistent` when you want to prevent the underlying texture from being reused.
    
    By default, images created from external sources have the `persistent` policy.

- Understand that `MTIFilter.outputImage` is a compute property.

    Each time you ask a filter for its output image, the filter may give you a new output image object even if the inputs are identical with the previous call. So reuse output images whenever possible.
    
    For example,

     ```Swift
    //          ╭→ filterB
    // filterA ─┤
    //          ╰→ filterC
    // 
    // filterB and filterC use filterA's output as their input.
    ```
    In this situation, the following solution:
    
    ```Swift
    let filterOutputImage = filterA.outputImage
    filterB.inputImage = filterOutputImage
    filterC.inputImage = filterOutputImage
    ```
    
    is better than:

    ```Swift
    filterB.inputImage = filterA.outputImage
    filterC.inputImage = filterA.outputImage
    ```

## Build Custom Filter

If you want to include the `MTIShaderLib.h` in your `.metal` file, you need to add `${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal/MetalPetal.framework/Headers` to the `Metal Compiler - Header Search Paths` (`MTL_HEADER_SEARCH_PATHS`).

### Simple single input/output filters

To build a custom unary filter, you can subclass `MTIUnaryImageRenderingFilter` and override the methods in the `SubclassingHooks` category. Examples: `MTIPixellateFilter`, `MTIVibranceFilter`, `MTIUnpremultiplyAlphaFilter`, `MTIPremultiplyAlphaFilter`, etc.

```ObjectiveC
@interface MTIPixellateFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float fractionalWidthOfAPixel;

@end

@implementation MTIPixellateFilter

- (instancetype)init {
    if (self = [super init]) {
        _fractionalWidthOfAPixel = 0.05;
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"pixellateEffect" libraryURL:[bundle URLForResource:@"default" withExtension:@"metallib"]];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"fractionalWidthOfAPixel": @(self.fractionalWidthOfAPixel)};
}

@end
```

### Fully custom filters

To build more complex filters, all you need to do is create a kernel (`MTIRenderPipelineKernel`/`MTIComputePipelineKernel`/`MTIMPSKernel`), then apply the kernel to the input image(s). Examples: `MTIChromaKeyBlendFilter`, `MTIBlendWithMaskFilter`, `MTIColorLookupFilter`, etc.

```ObjectiveC

@interface MTIChromaKeyBlendFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic) float thresholdSensitivity;

@property (nonatomic) float smoothing;

@property (nonatomic) MTIColor color;

@end

@implementation MTIChromaKeyBlendFilter

@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"chromaKeyBlend"]];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _thresholdSensitivity = 0.4;
        _smoothing = 0.1;
        _color = MTIColorMake(0.0, 1.0, 0.0, 1.0);
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!self.inputImage || !self.inputBackgroundImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputImage, self.inputBackgroundImage]
                                      parameters:@{@"color": [MTIVector vectorWithFloat4:(simd_float4){self.color.red, self.color.green, self.color.blue,self.color.alpha}],
                                    @"thresholdSensitivity": @(self.thresholdSensitivity),
                                               @"smoothing": @(self.smoothing)}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                               outputPixelFormat:self.outputPixelFormat];
}

@end
```

### Multiple draw calls in one render pass

You can use `MTIRenderCommand` to issue multiple draw calls in one render pass.

## Install

You can use [CocoaPods](https://cocoapods.org/) to install the lastest version.

```
use_frameworks!

pod 'MetalPetal'

# Swift extensions (optional).
pod 'MetalPetal/Swift'

```

## Contribute

Thank you for considering contributing to MetalPetal. Please read our [Contributing Guidelines](CONTRIBUTING.md).

## License

MetalPetal is MIT-licensed. [LICENSE](LICENSE)

The files in the `/MetalPetalDemo` directory are licensed under a separate license. [LICENSE.md](MetalPetalDemo/LICENSE.md)

Documentation is licensed CC-BY-4.0.
