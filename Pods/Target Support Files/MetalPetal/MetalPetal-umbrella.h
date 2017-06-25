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

#import "MTIContext.h"
#import "MTIFilter.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIImagePrivate.h"
#import "MTIImageRenderingContext.h"
#import "MTIStructs.h"

FOUNDATION_EXPORT double MetalPetalVersionNumber;
FOUNDATION_EXPORT const unsigned char MetalPetalVersionString[];

