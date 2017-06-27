# MetalPetal

A image processing framework based on Metal.

## Design

### MTIContext

Provides CommandQueue/TextureLoader/CVMetalTextureCache as well as Texture/RenderPipelineState/Function cache for rendering.

### MTIImage

A receipt/promise of a MTLTexture.

### MTIFilter

A render receipt builder.

### MTIImageRenderingContext

Provides image rendering operations and the required command buffer.
