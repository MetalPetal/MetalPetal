# MetalPetal

A image processing framework based on Metal.

## Design

### Goals

- Easy to use

- Performance

- Support MPS (Metal Performance Shaders)

- Support floating-point texture formats for filters

- Support vertex modification

- Swifty

- Extensibility

- Working with CoreImage/GPUImage

### Key Components

#### MTIContext

Provides CommandQueue/TextureLoader/CVMetalTextureCache as well as Texture/RenderPipelineState/Function cache for rendering.

#### MTIImage

A receipt/promise of a MTLTexture.

#### MTIFilter

A render receipt builder.

#### MTIImageRenderingContext

Provides image rendering operations and the required command buffer.
