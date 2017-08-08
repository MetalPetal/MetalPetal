# MetalPetal

An image processing framework based on Metal.

**MetalPetal is still in its early phase and isn't ready for day-to-day usage.**

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

#### MTIImagePromise

A `MTIImagePromise` is a "recipe" specifying how to create a texture with the specified kernel, parameters, and input.

#### MTIFilter

A `MTIFilter` represents an image processing effect and any parameters that control that effect. It produces a `MTIImage` object as output. To use a filter, you create a filter object, set its input images and parameters, and then access its output image. Typically, a filter class owns a static kernel (`MTIKernel`), when you access its `outputImage` property, it asks the kernel with the input images and parameters to produce a output `MTIImage`. 

#### MTIKernel

A `MTIKernel` represents an image processing routine. `MTIKernel` is responsible for creating the cooresponding render or compute pipeline state for the filter, as well as building the `MTIImagePromise` for a `MTIImage`.

### Concurrency Considerations

`MTIImage` objects are immutable, which means they can be shared safely among threads. 

However, `MTIFilter` objects are mutable and thus cannot be shared safely among threads.

A `MTIContext` contains a lot of states and caches thus cannot be shared safely among threads currently. We are still evaluating whether it's necessary to implement a thread-safe mechanism for `MTIContext` objects.

### Advantages over Core Image

- Fully customizable vertex and fragment functions.

- Works seemlessly with [GPUImage](https://github.com/BradLarson/GPUImage) and Core Image.

- Generally better performance. (Detailed benchmark data needed)

## Example Code

#### Create a `MTIImage`

```Swift
let imageFromCGImage = MTIImage(cgImage: cgImage)

let imageFromCIImage = MTIImage(ciImage: ciImage)

let imageFromCoreVideoPixelBuffer = MTIImage(cvPixelBuffer: pixelBuffer)

let imageFromContentsOfURL = MTIImage(contentsOf: url)
```

#### Create a filtered image

```Swift
let inputImage = ...

let filter = MTISaturationFilter()
filter.saturation = 0
filter.inputImage = inputImage

let outputImage = filter.outputImage
```

#### Render a `MTIImage`

```Swift
let context = MTIContext()

let image: MTIImage = ...

do {
    try context.render(image, to: pixelBuffer) 
    
    //context.makeCIImage(from: image)
    
    //context.makeCGImage(from: image)
} catch {
    print(error)
}
```

## Best Practices

- Reuse a `MTIContext` whenever possible.

    Contexts are heavyweight objects, so if you do create one, do so as early as possible, and reuse it each time you need to render a image.

- Use `MTIImage.cachePolicy` wisely.
    
    Use `MTIImageCachePolicyTransient` when you do not want to preserve the render result of a image, for example when the image is just an intermediate result in a filter chain, so the underlying texture of the render result can be reused. It is the most memory efficient option. However, when you ask the context to render a previously rendered image, it may re-render that image since its underlying texture has been reused.
    
    By default, a filter's output image has the `transient` policy.

    Use `MTIImageCachePolicyPersistent` when you want to prevent the underlying texture from being reused.
    
    By default, images created from external sources has the `persistent` policy.

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
    
## Install

We do not recommend you to use MetalPetal in your project right now.

However if you'd like to give it a try, you can use [CocoaPods](https://cocoapods.org/) to install the lastest version.

```
use_frameworks!

pod 'MetalPetal', :git => 'https://github.com/MetalPetal/MetalPetal.git'

# Swift extensions (optional).
pod 'MetalPetal/Swift', :git => 'https://github.com/MetalPetal/MetalPetal.git'

```

## Roadmap

We're going to release an alpha version of MetalPetal in Augest 2017 (hopefully).

You can follow our progress on the "Project" page. https://github.com/MetalPetal/MetalPetal/projects/1

## Contribute

Thank you for considering contributing to MetalPetal. Please read our [Contributing Guidelines](CONTRIBUTING.md).
