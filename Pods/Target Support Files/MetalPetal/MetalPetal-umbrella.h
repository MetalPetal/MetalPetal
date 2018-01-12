#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MTIAlphaPremultiplicationFilter.h"
#import "MTIBlendFilter.h"
#import "MTIBlendWithMaskFilter.h"
#import "MTIChromaKeyBlendFilter.h"
#import "MTICLAHEFilter.h"
#import "MTIColorLookupFilter.h"
#import "MTIColorMatrixFilter.h"
#import "MTICropFilter.h"
#import "MTIFilter.h"
#import "MTIImage+Filters.h"
#import "MTILensBlurFilter.h"
#import "MTIMPSConvolutionFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIMPSSobelFilter.h"
#import "MTIMultilayerCompositingFilter.h"
#import "MTIPixellateFilter.h"
#import "MTIRGBToneCurveFilter.h"
#import "MTITransformFilter.h"
#import "MTIUnaryImageRenderingFilter.h"
#import "MTIVibranceFilter.h"
#import "MTIComputePipelineKernel.h"
#import "MTIKernel.h"
#import "MTIMPSKernel.h"
#import "MTIMultilayerCompositeKernel.h"
#import "MTIRenderCommand.h"
#import "MTIRenderPipelineKernel.h"
#import "MetalPetal.h"
#import "MTIAlphaType.h"
#import "MTIBlendModes.h"
#import "MTIColor.h"
#import "MTIColorMatrix.h"
#import "MTIComputePipeline.h"
#import "MTIContext+Rendering.h"
#import "MTIContext.h"
#import "MTICVMetalTextureCache.h"
#import "MTICVPixelBufferPromise.h"
#import "MTIDrawableRendering.h"
#import "MTIError.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImageOrientation.h"
#import "MTIImagePromise.h"
#import "MTIImagePromiseDebug.h"
#import "MTIImageRenderingContext.h"
#import "MTILayer.h"
#import "MTILock.h"
#import "MTIMask.h"
#import "MTIPixelFormat.h"
#import "MTIRenderGraphOptimization.h"
#import "MTIRenderPassOutputDescriptor.h"
#import "MTIRenderPipeline.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTITextureDimensions.h"
#import "MTITexturePool.h"
#import "MTITransform.h"
#import "MTIVector.h"
#import "MTIVertex.h"
#import "MTIWeakToStrongObjectsMapTable.h"
#import "MTKTextureLoaderExtensions.h"
#import "MTIShaderLib.h"
#import "MTIImageView.h"

FOUNDATION_EXPORT double MetalPetalVersionNumber;
FOUNDATION_EXPORT const unsigned char MetalPetalVersionString[];

