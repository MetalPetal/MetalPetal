# MetalPetal

[![Swift](https://github.com/MetalPetal/MetalPetal/workflows/Swift/badge.svg)](https://github.com/MetalPetal/MetalPetal/actions?query=workflow%3ASwift)
<br/>
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2011%2B%20%7C%20tvOS%2013%2B%20%7C%20macOS%2010.13%2B-blue.svg)](#)
[![Version](https://img.shields.io/github/v/release/MetalPetal/MetalPetal?label=Release)](https://github.com/MetalPetal/MetalPetal/releases)
<br/>
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-%E2%80%8B%20%E2%9C%94-eee)](#)
[![Mac Catalyst](https://img.shields.io/badge/Mac%20Catalyst-%E2%80%8B%20%E2%9C%94-eee)](#)
[![Simulator](https://img.shields.io/badge/Simulator-%E2%80%8B%20%E2%9C%94-eee)](#)
<br/>
[![CocoaPods](https://img.shields.io/static/v1?label=CocoaPods&message=%E2%80%8B%20%E2%9C%94&color=eee&logo=CocoaPods&logoColor=white)](#cocoapods)
[![Swift PM](https://img.shields.io/static/v1?label=Swift%20PM&message=%E2%80%8B%20%E2%9C%94&color=eee&logo=Swift&logoColor=white)](#swift-package-manager)

An image processing framework based on Metal.

<!-- TOC depthFrom:2 -->

- [Design Overview](#design-overview)
    - [Goals](#goals)
    - [Core Components](#core-components)
        - [MTIContext](#mticontext)
        - [MTIImage](#mtiimage)
        - [MTIFilter](#mtifilter)
        - [MTIKernel](#mtikernel)
    - [Optimizations](#optimizations)
    - [Concurrency Considerations](#concurrency-considerations)
    - [Advantages over Core Image](#advantages-over-core-image)
- [Builtin Filters](#builtin-filters)
- [Example Code](#example-code)
    - [Create a `MTIImage`](#create-a-mtiimage)
    - [Apply a Filter](#apply-a-filter)
    - [Render a `MTIImage`](#render-a-mtiimage)
    - [Display a `MTIImage`](#display-a-mtiimage)
    - [Connect Filters (Swift)](#connect-filters-swift)
    - [Process Video Files](#process-video-files)
    - [Process Live Video (with VideoIO)](#process-live-video-with-videoio)
- [Best Practices](#best-practices)
- [Build Custom Filter](#build-custom-filter)
    - [Shader Function Arguments Encoding](#shader-function-arguments-encoding)
    - [Simple Single Input / Output Filters](#simple-single-input--output-filters)
    - [Fully Custom Filters](#fully-custom-filters)
    - [Multiple Draw Calls in One Render Pass](#multiple-draw-calls-in-one-render-pass)
    - [Custom Vertex Data](#custom-vertex-data)
    - [Custom Processing Module](#custom-processing-module)
- [Alpha Types](#alpha-types)
    - [Alpha Handling of Built-in Filters](#alpha-handling-of-built-in-filters)
- [Color Spaces](#color-spaces)
    - [Color Spaces for Inputs](#color-spaces-for-inputs)
    - [Color Spaces for Outputs](#color-spaces-for-outputs)
    - [Color Spaces for `CVPixelBuffer`](#color-spaces-for-cvpixelbuffer)
    - [Color Space Conversions](#color-space-conversions)
- [Extensions](#extensions)
    - [Working with SceneKit](#working-with-scenekit)
    - [Working with SpriteKit](#working-with-spritekit)
    - [Working with Core Image](#working-with-core-image)
    - [Working with JavaScript](#working-with-javascript)
    - [Texture Loader](#texture-loader)
- [Install](#install)
    - [CocoaPods](#cocoapods)
        - [Sub-pod `Swift`](#sub-pod-swift)
        - [Sub-pod `AppleSilicon`](#sub-pod-applesilicon)
    - [Swift Package Manager](#swift-package-manager)
- [iOS Simulator Support](#ios-simulator-support)
- [Quick Look Debug Support](#quick-look-debug-support)
- [Trivia](#trivia)
- [Contribute](#contribute)
- [License](#license)

<!-- /TOC -->

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

A `MTIFilter` represents an image processing effect and any parameters that control that effect. It produces a `MTIImage` object as output. To use a filter, you create a filter object, set its input images and parameters, and then access its output image. Typically, a filter class owns a static kernel (`MTIKernel`), when you access its `outputImage` property, it asks the kernel with the input images and parameters to produce an output `MTIImage`. 

#### MTIKernel

A `MTIKernel` represents an image processing routine. `MTIKernel` is responsible for creating the corresponding render or compute pipeline state for the filter, as well as building the `MTIImagePromise` for a `MTIImage`.

### Optimizations

MetalPetal does a lot of optimizations for you under the hood.

It automatically caches functions, kernel states, sampler states, etc.

It utilizes Metal features like programmable blending, memoryless render targets, resource heaps and metal performance shaders to make the render fast and efficient. On macOS, MetalPetal can also take advantage of the TBDR architecture of Apple silicon.

Before rendering, MetalPetal can look into your image render graph and figure out the minimal number of intermediate textures needed to do the rendering, saving memory, energy and time.

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
    - Hard Light
    - Soft Light
    - Darken
    - Lighten
    - Color Dodge
    - Add (Linear Dodge)
    - Color Burn
    - Linear Burn
    - Lighter Color
    - Darker Color
    - Vivid Light
    - Linear Light
    - Pin Light
    - Hard Mix
    - Difference
    - Exclusion
    - Subtract
    - Divide
    - Hue
    - Saturation
    - Color
    - Luminosity
    - ColorLookup512x512
    - [Custom Blend Mode](https://github.com/MetalPetal/MetalPetal/issues/70#issuecomment-792430483)

- Blend with Mask

- Transform

- Crop

- Pixellate

- Multilayer Composite

- MPS Convolution

- MPS Gaussian Blur

- MPS Definition

- MPS Sobel

- MPS Unsharp Mask

- MPS Box Blur

- [High Pass Skin Smoothing](https://github.com/YuAo/YUCIHighPassSkinSmoothing)

- [CLAHE (Contrast-Limited Adaptive Histogram Equalization)](https://github.com/YuAo/Accelerated-CLAHE)

- [Lens Blur (Hexagonal Bokeh Blur)](https://github.com/YuAo/HexagonalBokehBlur)

- [Surface Blur](https://github.com/MetalPetal/SurfaceBlur)

- Bulge Distortion

- Chroma Key Blend

- Color Halftone

- Dot Screen

- Round Corner (Circular/Continuous Curve)

- [All Core Image Filters](#working-with-core-image)

## Example Code

### Create a `MTIImage`

You can create a `MTIImage` object from nearly any source of image data, including:

- `URL`s referencing image files to be loaded
- Metal textures
- CoreVideo image or pixel buffers (`CVImageBufferRef` or `CVPixelBufferRef`)
- Image bitmap data in memory
- Texture data from a given texture or image asset name
- Core Image `CIImage` objects
- `MDLTexture` objects
- SceneKit and SpriteKit scenes

```Swift
let imageFromCGImage = MTIImage(cgImage: cgImage, isOpaque: true)

let imageFromCIImage = MTIImage(ciImage: ciImage)

let imageFromCoreVideoPixelBuffer = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)

let imageFromContentsOfURL = MTIImage(contentsOf: url)

// unpremultiply alpha if needed
let unpremultipliedAlphaImage = image.unpremultiplyingAlpha()
```

### Apply a Filter

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

### Display a `MTIImage`

```Swift
let imageView = MTIImageView(frame: self.view.bounds)

// You can optionally assign a `MTIContext` to the image view. If no context is assigned and `automaticallyCreatesContext` is set to `true` (the default value), a `MTIContext` is created automatically when the image view renders its content.
imageView.context = ...

imageView.image = image
```

If you'd like to move the GPU command encoding process out of the main thread, you can use a `MTIThreadSafeImageView`. You may assign a `MTIImage` to a `MTIThreadSafeImageView` in any thread.

### Connect Filters (Swift)

MetalPetal has a type-safe Swift API for connecting filters. You can use `=>` operator in `FilterGraph.makeImage` function to connect filters and get the output image.

Here are some examples:

```Swift
let image = try? FilterGraph.makeImage { output in
    inputImage => saturationFilter => exposureFilter => output
}
```

```Swift
let image = try? FilterGraph.makeImage { output in
    inputImage => saturationFilter => exposureFilter => contrastFilter => blendFilter.inputPorts.inputImage
    exposureFilter => blendFilter.inputPorts.inputBackgroundImage
    blendFilter => output
}
```

- You can connect unary filters (`MTIUnaryFilter`) directly using `=>`.

- For a filter with multiple inputs, you need to connect to one of its `inputPorts`.

- `=>` operator only works in `FilterGraph.makeImage` method.

- One and only one filter's output can be connected to `output`.

### Process Video Files

Working with `AVPlayer`:

```Swift
let context = try MTIContext(device: device)
let asset = AVAsset(url: videoURL)
let composition = MTIVideoComposition(asset: asset, context: context, queue: DispatchQueue.main, filter: { request in
    return FilterGraph.makeImage { output in
        request.anySourceImage! => filterA => filterB => output
    }!
}

let playerItem = AVPlayerItem(asset: asset)
playerItem.videoComposition = composition.makeAVVideoComposition()
player.replaceCurrentItem(with: playerItem)
player.play()
```

Export a video:

_[VideoIO](https://github.com/MetalPetal/VideoIO) is required for the following examples._

```Swift
import VideoIO

var configuration = AssetExportSession.Configuration(fileType: .mp4, videoSettings: .h264(videoSize: composition.renderSize), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 128 * 1000))
configuration.videoComposition = composition.makeAVVideoComposition()
self.exporter = try! AssetExportSession(asset: asset, outputURL: outputURL, configuration: configuration)
exporter.export(progress: { progress in
    
}, completion: { error in
    
})
```

### Process Live Video (with VideoIO)

_[VideoIO](https://github.com/MetalPetal/VideoIO) is required for this example._ 

```Swift
import VideoIO

// Setup Image View
let imageView = MTIImageView(frame: self.view.bounds)
...

// Setup Camera
let camera = Camera(captureSessionPreset: .hd1920x1080, configurator: .portraitFrontMirroredVideoOutput)
try camera.enableVideoDataOutput(on: DispatchQueue.main, delegate: self)
camera.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]

...

// AVCaptureVideoDataOutputSampleBufferDelegate

let filter = MTIColorInvertFilter()

func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return
    }
    let inputImage = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
    filter.inputImage = inputImage
    self.imageView.image = filter.outputImage
}

```

Please refer to the `CameraFilterView.swift` in the example project for more about previewing and recording filtered live video.

## Best Practices

- Reuse a `MTIContext` whenever possible.

    Contexts are heavyweight objects, so if you do create one, do so as early as possible, and reuse it each time you need to render an image.

- Use `MTIImage.cachePolicy` wisely.
    
    Use `MTIImageCachePolicyTransient` when you do not want to preserve the render result of an image, for example when the image is just an intermediate result in a filter chain, so the underlying texture of the render result can be reused. It is the most memory efficient option. However, when you ask the context to render a previously rendered image, it may re-render that image since its underlying texture has been reused.
    
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

If you want to include the `MTIShaderLib.h` in your `.metal` file, you need to add the path of `MTIShaderLib.h` file to the `Metal Compiler - Header Search Paths` (`MTL_HEADER_SEARCH_PATHS`) setting.

For example, if you use CocoaPods you can set the `MTL_HEADER_SEARCH_PATHS` to  `${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal/MetalPetal.framework/Headers` or `${PODS_ROOT}/MetalPetal/Frameworks/MetalPetal/Shaders`. If you use Swift Package Manager, set the `MTL_HEADER_SEARCH_PATHS` to `$(HEADER_SEARCH_PATHS)`

### Shader Function Arguments Encoding

MetalPetal has a built-in mechanism to encode shader function arguments for you. You can pass the shader function arguments as `name: value` dictionaries to the `MTIRenderPipelineKernel.apply(toInputImages:parameters:outputDescriptors:)`, `MTIRenderCommand(kernel:geometry:images:parameters:)`, etc.

For example, the parameter dictionary for the metal function `vibranceAdjust` can be:

```Swift
// Swift
let amount: Float = 1.0
let vibranceVector = float4(1, 1, 1, 1)
let parameters = ["amount": amount,
                  "vibranceVector": MTIVector(value: vibranceVector),
                  "avoidsSaturatingSkinTones": true,
                  "grayColorTransform": MTIVector(value: float3(0,0,0))]
```

```Metal
// vibranceAdjust metal function
fragment float4 vibranceAdjust(...,
                constant float & amount [[ buffer(0) ]],
                constant float4 & vibranceVector [[ buffer(1) ]],
                constant bool & avoidsSaturatingSkinTones [[ buffer(2) ]],
                constant float3 & grayColorTransform [[ buffer(3) ]])
{
    ...
}

```

The shader function argument types and the corresponding types to use in a parameter dictionary is listed below.

| Shader Function Argument Type | Swift | Objective-C | 
| :--- | :--- | :--- |
| float | Float | float |
| int | Int32 | int |
| uint | UInt32 | uint |
| bool | Bool | bool |
| simd (float2,float4,float4x4,int4, etc.) | simd (with `MetalPetal/Swift`) / MTIVector | MTIVector |
| struct | Data / MTIDataBuffer | NSData / MTIDataBuffer |
| other (float *, struct *, etc.) immutable | Data / MTIDataBuffer | NSData / MTIDataBuffer |
| other (float *, struct *, etc.) mutable | MTIDataBuffer | MTIDataBuffer |

### Simple Single Input / Output Filters

To build a custom unary filter, you can subclass `MTIUnaryImageRenderingFilter` and override the methods in the `SubclassingHooks` category. Examples: `MTIPixellateFilter`, `MTIVibranceFilter`, `MTIUnpremultiplyAlphaFilter`, `MTIPremultiplyAlphaFilter`, etc.

```ObjectiveC
//Objective-C

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

```Swift
//Swift

class MTIPixellateFilter: MTIUnaryImageRenderingFilter {
    
    var fractionalWidthOfAPixel: Float = 0.05

    override var parameters: [String : Any] {
        return ["fractionalWidthOfAPixel": fractionalWidthOfAPixel]
    }
    
    override class func fragmentFunctionDescriptor() -> MTIFunctionDescriptor {
        return MTIFunctionDescriptor(name: "pixellateEffect", libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main))
    }
}
```

### Fully Custom Filters

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

### Multiple Draw Calls in One Render Pass

You can use `MTIRenderCommand` to issue multiple draw calls in one render pass.

```Swift
// Create a draw call with kernelA, geometryA, and imageA.
let renderCommandA = MTIRenderCommand(kernel: self.kernelA, geometry: self.geometryA, images: [imageA], parameters: [:])

// Create a draw call with kernelB, geometryB, and imageB.
let renderCommandB = MTIRenderCommand(kernel: self.kernelB, geometry: self.geometryB, images: [imageB], parameters: [:])

// Create an output descriptor
let outputDescriptor = MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(width: outputWidth, height: outputHeight, depth: 1), pixelFormat: .bgra8Unorm, loadAction: .clear, storeAction: .store)

// Get the output images, the output image count is equal to the output descriptor count.
let images = MTIRenderCommand.images(byPerforming: [renderCommandA, renderCommandB], outputDescriptors: [outputDescriptor])
```

You can also create multiple output descriptors to output multiple images in one render pass (MRT, See https://en.wikipedia.org/wiki/Multiple_Render_Targets).

### Custom Vertex Data

When `MTIVertex` cannot fit your needs, you can implement the `MTIGeometry` protocol to provide your custom vertex data to the command encoder.

Use the `MTIRenderCommand` API to issue draw calls and pass your custom `MTIGeometry`.

### Custom Processing Module

In rare scenarios, you may want to access the underlying texture directly, use multiple MPS kernels in one render pass, do 3D rendering, or encode the render commands yourself.

`MTIImagePromise` protocol provides direct access to the underlying texture and the render context for a step in MetalPetal.

You can create new input sources or fully custom processing units by implementing the `MTIImagePromise` protocol. You will need to import an additional module to do so. 

Objective-C

```
@import MetalPetal.Extension;
```

Swift

```
// CocoaPods
import MetalPetal.Extension

// Swift Package Manager
import MetalPetalObjectiveC.Extension
```

See the implementation of `MTIComputePipelineKernel`, `MTICLAHELUTRecipe` or `MTIImage` for example.

## Alpha Types

If an alpha channel is used in an image, there are two common representations that are available: unpremultiplied (straight/unassociated) alpha, and premultiplied (associated) alpha.

With unpremultiplied alpha, the RGB components represent the color of the pixel, disregarding its opacity.

With premultiplied alpha, the RGB components represent the color of the pixel, adjusted for its opacity by multiplication.

MetalPetal handles alpha type explicitly. You are responsible for providing the correct alpha type during image creation.

There are three alpha types in MetalPetal.

`MTIAlphaType.nonPremultiplied`: the alpha value in the image is not premultiplied.

`MTIAlphaType.premultiplied`: the alpha value in the image is premultiplied.

`MTIAlphaType.alphaIsOne`: there's no alpha channel in the image or the image is opaque.

Typically, `CGImage`, `CVPixelBuffer` and `CIImage` objects have premultiplied alpha channels. `MTIAlphaType.alphaIsOne` is strongly recommended if the image is opaque, e.g. a `CVPixelBuffer` from camera feed, or a `CGImage` loaded from a `jpg` file.

You can call `unpremultiplyingAlpha()` or `premultiplyingAlpha()` on a `MTIImage` to convert the alpha type of the image.

For performance reasons, alpha type validation only happens in debug build.

### Alpha Handling of Built-in Filters

- Most of the filters in MetalPetal accept unpremultiplied alpha and opaque images and output unpremultiplied alpha images.

- Filters with `outputAlphaType` property accept inputs of all alpha types. And you can use `outputAlphaType` to specify the alpha type of the output image.
    
    e.g. `MTIBlendFilter`, `MTIMultilayerCompositingFilter`, `MTICoreImageUnaryFilter`, `MTIRGBColorSpaceConversionFilter`
    
- Filters that do not actually modify colors have passthrough alpha handling rule, that means the alpha types of the output images are the same with the input images.

    e.g. `MTITransformFilter`, `MTICropFilter`, `MTIPixellateFilter`, `MTIBulgeDistortionFilter`

For more about alpha types and alpha compositing, please refer to [this amazing interactive article](https://ciechanow.ski/alpha-compositing/) by Bartosz Ciechanowski.

## Color Spaces

Color spaces are vital for image processing. The numeric values of the red, green, and blue components have no meaning without a color space.

Before continuing on how MetalPetal handles color spaces, you may want to know what a color space is and how it affects the representation of color values. There are many articles on the web explaining color spaces, to get started, the suggestion is [Color Spaces - by Bartosz Ciechanowski](https://ciechanow.ski/color-spaces/).

Different softwares and frameworks have different ways of handling color spaces. For example, Photoshop has a default sRGB IEC61966-2.1 working color space, while Core Image, by default, uses linear sRGB working color space.

Metal textures do not store any color space information with them. Most of the color space handling in MetalPetal happens during the input (`MTIImage(...)`) and the output (`MTIContext.render...`) of image data.

### Color Spaces for Inputs

Specifying a color space for an input means that MetalPetal should convert the source color values to the specified color space during the creation of the texture.

- When loading from `URL` or `CGImage`, you can specify which color space you'd like the texture data to be in, using `MTICGImageLoadingOptions`. If you do not specify any options when loading an image, the device RGB color space is used (`MTICGImageLoadingOptions.default`). A `nil` color space disables color matching, this is the equivalent of using the color space of the input image to create `MTICGImageLoadingOptions`. If the model of the specified color space is not RGB, the device RGB color space is used as a fallback.

- When loading from `CIImage`, you can specify which color space you'd like the texture data to be in, using `MTICIImageRenderingOptions`. If you do not specify any options when loading a `CIImage`, the device RGB color space is used (`MTICIImageRenderingOptions.default`). A `nil` color space disables color matching, color values are loaded in the working color space of the `CIContext`.

### Color Spaces for Outputs

When specifying a color space for an output, the color space serves more like a tag which is used to communicate with the rest of the system on how to represent the color values in the output. There is no actual color space conversion performed. 

- You can specify the color space of an output `CGImage` using `MTIContext.makeCGImage...` or `MTIContext.startTaskTo...` methods with a `colorSpace` parameter.

- You can specify the color space of an output `CIImage` using `MTICIImageCreationOptions`.

MetalPetal assumes that the output color values are in device RGB color space when no output color space is specified.

### Color Spaces for `CVPixelBuffer`

MetalPetal uses `CVMetalTextureCache` and `IOSurface` to directly map `CVPixelBuffer`s to Metal textures. So you cannot specify a color space for loading from or rendering to a `CVPixelBuffer`. However you can specify whether to use a texture with a sRGB pixel format for the mapping.

In Metal, if the pixel format name has the `_sRGB` suffix, then sRGB gamma compression and decompression are applied during the reading and writing of color values in the pixel. That means a texture with the `_sRGB` pixel format assumes the color values it stores are sRGB gamma corrected, when the color values are read in a shader, sRGB to linear RGB conversions are performed. When the color values are written in a shader, linear RGB to sRGB conversions are performed.

### Color Space Conversions

You can use `MTIRGBColorSpaceConversionFilter` to perform color space conversions. Color space conversion functions are also available in `MTIShaderLib.h`.

- `metalpetal::sRGBToLinear` (sRGB IEC61966-2.1 to linear sRGB)
- `metalpetal::linearToSRGB` (linear sRGB to sRGB IEC61966-2.1)
- `metalpetal::linearToITUR709` (linear sRGB to ITU-R 709)
- `metalpetal::ITUR709ToLinear` (ITU-R 709 to linear sRGB)

## Extensions

### Working with SceneKit

You can use `MTISCNSceneRenderer` to generate `MTIImage`s from a `SCNScene`. You may want to handle the SceneKit renderer's linear RGB color space, see issue [#76 The image from SceneKit is darker than normal](https://github.com/MetalPetal/MetalPetal/issues/76).

### Working with SpriteKit

You can use `MTISKSceneRenderer` to generate `MTIImage`s from a `SKScene`.

### Working with Core Image

You can create `MTIImage`s from `CIImage`s.

You can render a `MTIImage` to a `CIImage` using a `MTIContext`.

You can use a `CIFilter` directly with `MTICoreImageKernel` or the `MTICoreImageUnaryFilter` class. (Swift Only)

### Working with JavaScript

See [MetalPetalJS](https://github.com/MetalPetal/MetalPetalJS)

With MetalPetalJS you can create render pipelines and filters using JavaScript, making it possible to download your filters/renderers from "the cloud".

### Texture Loader

It is recommended that you use APIs that accept `MTICGImageLoadingOptions` to load `CGImage`s and images from `URL`, instead of using APIs that accept `MTKTextureLoaderOption`.

When you use APIs that accept `MTKTextureLoaderOption`, MetalPetal, by default, uses `MTIDefaultTextureLoader` to load `CGImage`s, images from `URL`, and named images. `MTIDefaultTextureLoader` uses `MTKTextureLoader` internally and has some workarounds for `MTKTextureLoader`'s inconsistencies and bugs at a small performance cost. You can also create your own texture loader by implementing the `MTITextureLoader` protocol. Then assign your texture loader class to `MTIContextOptions.textureLoaderClass` when creating a `MTIContext`.

## Install

### CocoaPods

You can use [CocoaPods](https://cocoapods.org/) to install the latest version.

```
use_frameworks!

pod 'MetalPetal'

# Required if you are using Swift.
pod 'MetalPetal/Swift'

# Recommended if you'd like to run MetalPetal on Apple silicon Macs.
pod 'MetalPetal/AppleSilicon'

```

#### Sub-pod `Swift`

Provides Swift-specific additions and modifications to the Objective-C APIs to improve their mapping into Swift. Highly recommended if you are using Swift.

#### Sub-pod `AppleSilicon`

Provides the default shader library compiled in Metal Shading Language v2.3 which is required for enabling programmable blending support on Apple silicon Macs.

### Swift Package Manager

[Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

## iOS Simulator Support

MetalPetal can run on Simulator with Xcode 11+ and macOS 10.15+.

`MetalPerformanceShaders.framework` is not available on Simulator, so filters that rely on `MetalPerformanceShaders`, such as `MTIMPSGaussianBlurFilter`, `MTICLAHEFilter`, do not work.

Simulator supports fewer features or different implementation limits than an actual Apple GPU. See [Developing Metal Apps that Run in Simulator](https://developer.apple.com/documentation/metal/developing_metal_apps_that_run_in_simulator) for detail.

## Quick Look Debug Support

If you do a Quick Look on a `MTIImage`, it'll show you the image graph that you constructed to produce that image.

![Quick Look Debug Preview](https://user-images.githubusercontent.com/1234944/116965587-c6a0a280-ace0-11eb-8918-2f36d1d6114c.jpg)

## Trivia

[Why Objective-C?](https://github.com/MetalPetal/MetalPetal/issues/52)

## Contribute

Thank you for considering contributing to MetalPetal. Please read our [Contributing Guidelines](CONTRIBUTING.md).

## License

MetalPetal is MIT-licensed. [LICENSE](LICENSE)

The files in the `/MetalPetalExamples` directory are licensed under a separate license. [LICENSE.md](MetalPetalExamples/LICENSE.md)

Documentation is licensed CC-BY-4.0.
