# MetalPetal

A image processing framework based on Metal.

**MetalPetal is still in its early phase and isn't ready for day-to-day usage.**

## Design

### Goals

- Easy to use

- Performance

- Support MPS (Metal Performance Shaders)

- Support both render and compute pipeline

- Swifty

- Extensibility

- Working with CoreImage/GPUImage

### Key Components

#### MTIContext

Provides CommandQueue/TextureLoader/CVMetalTextureCache as well as Texture/RenderPipelineState/Function cache for rendering.

It also provides an evaluation context for `MTIImage`.

#### MTIImage

A recipe/promise of a `MTLTexture`.

#### MTIFilter

A `MTIImage` builder.

#### MTIKernel

The processing routine for `MTIFilter`. `MTIKernel` is responsible for creating cooresponding render/compute pipeline state for the filter, and building the recipe/promise for a `MTIImage`.

### Concurrency Considerations

`MTIImage` is designed to be immutable, so you can use a `MTIImage` in multiple threads.

However, `MTIFilter` objects are mutable and thus cannot be shared safely among threads.

`MTIContext` contains a lot of states and caches and cannot be shared safely among threads **currently**.

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

You can follow the progress on the "Project" page. https://github.com/MetalPetal/MetalPetal/projects/1

## Contribute

Thank you for considering contributing to MetalPetal. Please read our [Contributing Guidelines](CONTRIBUTING.md).
