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
#import "MTIColorInvertFilter.h"
#import "MTIColorMatrixFilter.h"
#import "MTIExposureFilter.h"
#import "MTIImage+Filters.h"
#import "MTIMPSConvolutionFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIMultilayerCompositingFilter.h"
#import "MTIOverlayBlendFilter.h"
#import "MTISaturationFilter.h"
#import "MTIUnaryImageFilter.h"
#import "MTIComputePipelineKernel.h"
#import "MTIKernel.h"
#import "MTIMPSKernel.h"
#import "MTIMultilayerCompositeKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MetalPetal.h"
#import "MTIBlendModes.h"
#import "MTIColor.h"
#import "MTIComputePipeline.h"
#import "MTIContext+Rendering.h"
#import "MTIContext.h"
#import "MTICVPixelBufferPromise.h"
#import "MTIDrawableRendering.h"
#import "MTIError.h"
#import "MTIFilter.h"
#import "MTIFilterUtilities.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImagePromise.h"
#import "MTIImageRenderingContext.h"
#import "MTILock.h"
#import "MTIRenderPipeline.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTITextureDimensions.h"
#import "MTITexturePool.h"
#import "MTIVector.h"
#import "MTIVertex.h"
#import "MTIWeakToStrongObjectsMapTable.h"
#import "MTIShaderTypes.h"
#import "MTIImageView.h"

FOUNDATION_EXPORT double MetalPetalVersionNumber;
FOUNDATION_EXPORT const unsigned char MetalPetalVersionString[];

